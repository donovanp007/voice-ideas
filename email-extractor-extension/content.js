// Content Script - Runs on web pages to extract emails with context

(function() {
  'use strict';

  const EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;

  // School staff page detection patterns
  const STAFF_PAGE_INDICATORS = [
    /staff/i, /faculty/i, /teacher/i, /directory/i, /team/i,
    /employee/i, /personnel/i, /administration/i, /contact/i,
    /our-team/i, /meet-the/i, /about-us/i, /leadership/i
  ];

  // Common job title patterns
  const JOB_TITLE_PATTERNS = [
    /principal/i, /teacher/i, /professor/i, /instructor/i,
    /director/i, /coordinator/i, /counselor/i, /librarian/i,
    /secretary/i, /assistant/i, /administrator/i, /superintendent/i,
    /dean/i, /head\s+of/i, /department/i, /coach/i, /nurse/i,
    /specialist/i, /manager/i, /aide/i, /tutor/i, /advisor/i,
    /registrar/i, /custodian/i, /security/i, /receptionist/i
  ];

  /**
   * Deobfuscate email addresses
   */
  function deobfuscateEmail(text) {
    if (!text) return '';
    let result = text;
    result = result.replace(/\[at\]/gi, '@');
    result = result.replace(/\(at\)/gi, '@');
    result = result.replace(/\s+at\s+/gi, '@');
    result = result.replace(/\[dot\]/gi, '.');
    result = result.replace(/\(dot\)/gi, '.');
    result = result.replace(/\s+dot\s+/gi, '.');
    return result;
  }

  /**
   * Validate email address
   */
  function isValidEmail(email) {
    if (!email || email.length < 5) return false;
    if (!email.includes('@') || !email.includes('.')) return false;

    const blacklist = [
      'example.com', 'test.com', 'email.com', 'domain.com',
      'your-email', 'youremail', 'name@', 'user@', 'info@example',
      '@2x.', '@3x.', '@media', '.png', '.jpg', '.gif', '.svg',
      'noreply', 'no-reply', 'donotreply', 'sentry.io', 'wixpress'
    ];

    return !blacklist.some(bl => email.includes(bl));
  }

  /**
   * Clean and normalize text
   */
  function cleanText(text) {
    if (!text) return '';
    return text.replace(/\s+/g, ' ').trim();
  }

  /**
   * Check if current page is likely a school staff page
   */
  function detectStaffPage() {
    const url = window.location.href.toLowerCase();
    const title = document.title.toLowerCase();
    const h1 = document.querySelector('h1')?.textContent?.toLowerCase() || '';

    const textToCheck = url + ' ' + title + ' ' + h1;

    for (const pattern of STAFF_PAGE_INDICATORS) {
      if (pattern.test(textToCheck)) {
        return { isStaffPage: true, indicator: pattern.toString(), url: window.location.href, title: document.title };
      }
    }

    const staffCardCount = document.querySelectorAll('.staff-card, .staff-member, .team-member, [class*="staff"], [class*="faculty"], [class*="employee"]').length;
    if (staffCardCount >= 3) {
      return { isStaffPage: true, indicator: 'multiple-staff-cards', url: window.location.href, title: document.title };
    }

    return { isStaffPage: false };
  }

  /**
   * Extract job title from text
   */
  function extractJobTitle(text) {
    if (!text) return '';
    const lines = text.split(/[\n\r]+/).map(l => l.trim()).filter(l => l);
    for (const line of lines) {
      for (const pattern of JOB_TITLE_PATTERNS) {
        if (pattern.test(line) && line.length < 100) {
          return cleanText(line);
        }
      }
    }
    return '';
  }

  /**
   * Extract name from element
   */
  function extractName(element) {
    const nameSelectors = ['h1', 'h2', 'h3', 'h4', '.name', '.person-name', '.staff-name', '[class*="name"]', '.card-title', 'strong', 'b'];

    for (const selector of nameSelectors) {
      const nameEl = element.querySelector(selector);
      if (nameEl) {
        const text = cleanText(nameEl.textContent);
        if (text && /^[A-Za-z\s\.\-']{2,60}$/.test(text) && text.split(/\s+/).length <= 5) {
          let isJobTitle = false;
          for (const pattern of JOB_TITLE_PATTERNS) {
            if (pattern.test(text)) { isJobTitle = true; break; }
          }
          if (!isJobTitle) return text;
        }
      }
    }
    return '';
  }

  // ==================== EXTRACTION METHODS ====================

  /**
   * Extract emails from mailto: links (MOST RELIABLE)
   */
  function extractFromMailtoLinks() {
    const results = [];
    const seen = new Set();
    const links = document.querySelectorAll('a[href^="mailto:"]');

    links.forEach(link => {
      const href = link.getAttribute('href');
      if (!href) return;

      const email = href.replace('mailto:', '').split('?')[0].toLowerCase().trim();
      if (!email || seen.has(email) || !isValidEmail(email)) return;
      seen.add(email);

      let name = '';
      let jobTitle = '';

      // Check link text for name
      const linkText = cleanText(link.textContent);
      if (linkText && !linkText.includes('@') && /^[A-Za-z\s\.\-']{2,60}$/.test(linkText)) {
        name = linkText;
      }

      // Check parent elements for context
      let parent = link.parentElement;
      for (let i = 0; i < 5 && parent; i++) {
        if (!name) name = extractName(parent);
        if (!jobTitle) jobTitle = extractJobTitle(parent.textContent || '');
        if (name && jobTitle) break;
        parent = parent.parentElement;
      }

      results.push({ name, email, jobTitle, source: 'mailto' });
    });

    return results;
  }

  /**
   * Extract emails from visible text content
   */
  function extractFromTextContent() {
    const results = [];
    const seen = new Set();
    const textContent = document.body.innerText || '';

    // Direct matches
    const matches = textContent.match(EMAIL_REGEX) || [];
    matches.forEach(email => {
      email = email.toLowerCase();
      if (!seen.has(email) && isValidEmail(email)) {
        seen.add(email);
        results.push({ name: '', email, jobTitle: '', source: 'text' });
      }
    });

    // Deobfuscated matches
    const deobfuscated = deobfuscateEmail(textContent);
    const deobMatches = deobfuscated.match(EMAIL_REGEX) || [];
    deobMatches.forEach(email => {
      email = email.toLowerCase();
      if (!seen.has(email) && isValidEmail(email)) {
        seen.add(email);
        results.push({ name: '', email, jobTitle: '', source: 'text-deob' });
      }
    });

    return results;
  }

  /**
   * Extract emails from data attributes
   */
  function extractFromDataAttributes() {
    const results = [];
    const seen = new Set();
    const allElements = document.querySelectorAll('*');

    allElements.forEach(el => {
      for (const attr of el.attributes) {
        if (attr.name.startsWith('data-')) {
          const value = deobfuscateEmail(attr.value);
          const matches = value.match(EMAIL_REGEX) || [];
          matches.forEach(email => {
            email = email.toLowerCase();
            if (!seen.has(email) && isValidEmail(email)) {
              seen.add(email);
              results.push({ name: '', email, jobTitle: '', source: 'data-attr' });
            }
          });
        }
      }
    });

    return results;
  }

  /**
   * Extract from onclick/onmouseover handlers
   */
  function extractFromEventHandlers() {
    const results = [];
    const seen = new Set();
    const elements = document.querySelectorAll('[onclick], [onmouseover], [onmouseenter]');

    elements.forEach(el => {
      ['onclick', 'onmouseover', 'onmouseenter'].forEach(handler => {
        const value = el.getAttribute(handler);
        if (value) {
          const matches = value.match(EMAIL_REGEX) || [];
          matches.forEach(email => {
            email = email.toLowerCase();
            if (!seen.has(email) && isValidEmail(email)) {
              seen.add(email);
              results.push({ name: '', email, jobTitle: '', source: 'handler' });
            }
          });
        }
      });
    });

    return results;
  }

  /**
   * Extract from title/alt/aria-label attributes
   */
  function extractFromHiddenContent() {
    const results = [];
    const seen = new Set();

    document.querySelectorAll('[title], [alt], [aria-label]').forEach(el => {
      ['title', 'alt', 'aria-label'].forEach(attr => {
        const value = el.getAttribute(attr);
        if (value) {
          const deob = deobfuscateEmail(value);
          const matches = deob.match(EMAIL_REGEX) || [];
          matches.forEach(email => {
            email = email.toLowerCase();
            if (!seen.has(email) && isValidEmail(email)) {
              seen.add(email);
              results.push({ name: '', email, jobTitle: '', source: 'hidden' });
            }
          });
        }
      });
    });

    return results;
  }

  /**
   * Extract from staff cards with context
   */
  function extractFromStaffCards() {
    const results = [];
    const seen = new Set();

    const cardSelectors = [
      '.staff-card', '.staff-member', '.team-member', '.faculty-member',
      '.employee-card', '.person-card', '.profile-card', '.member-card',
      '.directory-item', '.contact-card', '[class*="staff-"]', '[class*="faculty-"]',
      '[class*="employee-"]', '[class*="team-member"]', '.card', '.profile',
      'article', 'li[class*="member"]', 'div[class*="member"]'
    ];

    const allCards = new Set();
    cardSelectors.forEach(selector => {
      try { document.querySelectorAll(selector).forEach(card => allCards.add(card)); } catch (e) {}
    });

    allCards.forEach(card => {
      const html = deobfuscateEmail(card.innerHTML);
      const text = card.textContent || '';
      const emailMatches = html.match(EMAIL_REGEX) || [];

      emailMatches.forEach(email => {
        email = email.toLowerCase();
        if (seen.has(email) || !isValidEmail(email)) return;
        seen.add(email);

        const name = extractName(card);
        let jobTitle = extractJobTitle(text);

        if (!jobTitle) {
          const titleSelectors = ['.job-title', '.position', '.role', '[class*="title"]', '[class*="position"]', '.subtitle', 'small'];
          for (const sel of titleSelectors) {
            const titleEl = card.querySelector(sel);
            if (titleEl) {
              const titleText = cleanText(titleEl.textContent);
              for (const pattern of JOB_TITLE_PATTERNS) {
                if (pattern.test(titleText)) { jobTitle = titleText; break; }
              }
              if (jobTitle) break;
            }
          }
        }

        results.push({ name, email, jobTitle, source: 'card' });
      });
    });

    return results;
  }

  /**
   * Extract from tables
   */
  function extractFromTables() {
    const results = [];
    const seen = new Set();

    document.querySelectorAll('table').forEach(table => {
      table.querySelectorAll('tr').forEach(row => {
        const rowText = deobfuscateEmail(row.textContent || '');
        const emailMatches = rowText.match(EMAIL_REGEX) || [];

        emailMatches.forEach(email => {
          email = email.toLowerCase();
          if (seen.has(email) || !isValidEmail(email)) return;
          seen.add(email);

          const cells = row.querySelectorAll('td, th');
          let name = '';
          let jobTitle = '';

          cells.forEach((cell, index) => {
            const cellText = cleanText(cell.textContent);
            if (index === 0 && !cellText.includes('@') && /^[A-Za-z\s\.\-']{2,60}$/.test(cellText)) {
              name = cellText;
            }
            if (!jobTitle) {
              for (const pattern of JOB_TITLE_PATTERNS) {
                if (pattern.test(cellText)) { jobTitle = cellText; break; }
              }
            }
          });

          results.push({ name, email, jobTitle, source: 'table' });
        });
      });
    });

    return results;
  }

  /**
   * Extract from inline scripts (deep scan only)
   */
  function extractFromScripts() {
    const results = [];
    const seen = new Set();

    document.querySelectorAll('script:not([src])').forEach(script => {
      const content = script.textContent || '';
      const matches = content.match(EMAIL_REGEX) || [];
      matches.forEach(email => {
        email = email.toLowerCase();
        if (!seen.has(email) && isValidEmail(email)) {
          seen.add(email);
          results.push({ name: '', email, jobTitle: '', source: 'script' });
        }
      });
    });

    return results;
  }

  // ==================== MAIN EXTRACTION ====================

  /**
   * Main extraction function - returns array of {name, email, jobTitle}
   */
  function extractAllWithContext(deepScan = false) {
    const allResults = [];
    const seenEmails = new Set();

    // ALL sources run on basic extraction
    const sources = [
      extractFromMailtoLinks(),
      extractFromTextContent(),
      extractFromDataAttributes(),
      extractFromEventHandlers(),
      extractFromHiddenContent(),
      extractFromStaffCards(),
      extractFromTables()
    ];

    // Deep scan adds scripts
    if (deepScan) {
      sources.push(extractFromScripts());
    }

    // Merge results, preferring entries with more context
    sources.forEach(sourceResults => {
      sourceResults.forEach(result => {
        if (seenEmails.has(result.email)) {
          const existing = allResults.find(r => r.email === result.email);
          if (existing) {
            if (!existing.name && result.name) existing.name = result.name;
            if (!existing.jobTitle && result.jobTitle) existing.jobTitle = result.jobTitle;
          }
        } else {
          seenEmails.add(result.email);
          allResults.push(result);
        }
      });
    });

    return allResults.sort((a, b) => a.email.localeCompare(b.email));
  }

  /**
   * Legacy function for backward compatibility
   */
  function extractAllEmails(deepScan = false) {
    return extractAllWithContext(deepScan).map(r => r.email);
  }

  // Listen for messages from popup
  chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'extractEmails') {
      const emails = extractAllEmails(request.deepScan || false);
      sendResponse({ emails, count: emails.length });
    } else if (request.action === 'extractWithContext') {
      const results = extractAllWithContext(request.deepScan || false);
      sendResponse({ results, count: results.length });
    } else if (request.action === 'detectStaffPage') {
      sendResponse(detectStaffPage());
    } else if (request.action === 'ping') {
      sendResponse({ status: 'ready' });
    }
    return true;
  });

  console.log('📧 Email Extractor v2.1 loaded');
})();
