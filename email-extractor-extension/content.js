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
   * Check if current page is likely a school staff page
   */
  function detectStaffPage() {
    const url = window.location.href.toLowerCase();
    const title = document.title.toLowerCase();
    const h1 = document.querySelector('h1')?.textContent?.toLowerCase() || '';

    const textToCheck = url + ' ' + title + ' ' + h1;

    for (const pattern of STAFF_PAGE_INDICATORS) {
      if (pattern.test(textToCheck)) {
        return {
          isStaffPage: true,
          indicator: pattern.toString(),
          url: window.location.href,
          title: document.title
        };
      }
    }

    // Check for multiple staff cards
    const staffCardCount = document.querySelectorAll(
      '.staff-card, .staff-member, .team-member, [class*="staff"], [class*="faculty"], [class*="employee"]'
    ).length;

    if (staffCardCount >= 3) {
      return {
        isStaffPage: true,
        indicator: 'multiple-staff-cards',
        url: window.location.href,
        title: document.title
      };
    }

    return { isStaffPage: false };
  }

  /**
   * Clean and normalize text
   */
  function cleanText(text) {
    if (!text) return '';
    return text.replace(/\s+/g, ' ').trim();
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

    // Look for common title formats
    const titlePatterns = [
      /(?:title|position|role)[\s:]+([^\n]+)/i,
      /(?:^|\n)([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:Teacher|Principal|Director|Coordinator|Assistant|Manager|Specialist))/m
    ];

    for (const pattern of titlePatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        return cleanText(match[1]);
      }
    }

    return '';
  }

  /**
   * Extract name from element or nearby content
   */
  function extractName(element) {
    // Priority selectors for name
    const nameSelectors = [
      'h1', 'h2', 'h3', 'h4',
      '.name', '.person-name', '.staff-name', '.member-name',
      '[class*="name"]', '[class*="title"]:not([class*="job"])',
      '.heading', '.card-title', 'strong', 'b'
    ];

    for (const selector of nameSelectors) {
      const nameEl = element.querySelector(selector);
      if (nameEl) {
        const text = cleanText(nameEl.textContent);
        // Validate it looks like a name (2-4 words, no special chars)
        if (text && /^[A-Za-z\s\.\-']{2,60}$/.test(text) && text.split(/\s+/).length <= 5) {
          // Filter out job titles from name field
          let isJobTitle = false;
          for (const pattern of JOB_TITLE_PATTERNS) {
            if (pattern.test(text)) {
              isJobTitle = true;
              break;
            }
          }
          if (!isJobTitle) {
            return text;
          }
        }
      }
    }

    // Try to get from aria-label or title
    const ariaLabel = element.getAttribute('aria-label');
    if (ariaLabel && /^[A-Za-z\s\.\-']{2,60}$/.test(ariaLabel)) {
      return cleanText(ariaLabel);
    }

    return '';
  }

  /**
   * Extract staff data from card-like elements
   */
  function extractFromStaffCards() {
    const results = [];
    const seen = new Set();

    // Comprehensive card selectors
    const cardSelectors = [
      '.staff-card', '.staff-member', '.team-member', '.faculty-member',
      '.employee-card', '.person-card', '.profile-card', '.member-card',
      '.directory-item', '.contact-card', '.people-item', '.user-card',
      '[class*="staff-"]', '[class*="faculty-"]', '[class*="teacher-"]',
      '[class*="employee-"]', '[class*="team-member"]', '[class*="person-"]',
      '.card', '.profile', '.bio', 'article', '.grid-item',
      'li[class*="member"]', 'div[class*="member"]', 'tr[class*="staff"]'
    ];

    const allCards = new Set();
    cardSelectors.forEach(selector => {
      try {
        document.querySelectorAll(selector).forEach(card => allCards.add(card));
      } catch (e) {}
    });

    allCards.forEach(card => {
      const html = card.innerHTML;
      const text = card.textContent || '';
      const deobfuscatedHtml = deobfuscateEmail(html);

      // Find emails in card
      const emailMatches = deobfuscatedHtml.match(EMAIL_REGEX) || [];

      emailMatches.forEach(email => {
        email = email.toLowerCase();
        if (seen.has(email)) return;

        // Validate email
        if (!isValidEmail(email)) return;

        seen.add(email);

        // Extract name
        let name = extractName(card);

        // Extract job title
        let jobTitle = extractJobTitle(text);

        // If no job title found, look for specific elements
        if (!jobTitle) {
          const titleSelectors = [
            '.job-title', '.position', '.role', '.title',
            '[class*="title"]', '[class*="position"]', '[class*="role"]',
            '.subtitle', '.designation', 'small', '.meta'
          ];

          for (const selector of titleSelectors) {
            const titleEl = card.querySelector(selector);
            if (titleEl) {
              const titleText = cleanText(titleEl.textContent);
              if (titleText && titleText.length < 100) {
                // Check if this looks like a job title, not a name
                for (const pattern of JOB_TITLE_PATTERNS) {
                  if (pattern.test(titleText)) {
                    jobTitle = titleText;
                    break;
                  }
                }
                if (jobTitle) break;
              }
            }
          }
        }

        results.push({
          name: name,
          email: email,
          jobTitle: jobTitle,
          source: 'staff-card'
        });
      });
    });

    return results;
  }

  /**
   * Extract from mailto links with context
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

      // Try to find name and title from surrounding context
      let name = '';
      let jobTitle = '';

      // Check link text
      const linkText = cleanText(link.textContent);
      if (linkText && !linkText.includes('@') && /^[A-Za-z\s\.\-']{2,60}$/.test(linkText)) {
        name = linkText;
      }

      // Check parent elements for context
      let parent = link.parentElement;
      for (let i = 0; i < 5 && parent; i++) {
        const parentText = parent.textContent || '';

        if (!name) {
          name = extractName(parent);
        }

        if (!jobTitle) {
          jobTitle = extractJobTitle(parentText);
        }

        if (name && jobTitle) break;
        parent = parent.parentElement;
      }

      results.push({
        name: name,
        email: email,
        jobTitle: jobTitle,
        source: 'mailto-link'
      });
    });

    return results;
  }

  /**
   * Extract from table rows (common in staff directories)
   */
  function extractFromTables() {
    const results = [];
    const seen = new Set();

    document.querySelectorAll('table').forEach(table => {
      const rows = table.querySelectorAll('tr');

      rows.forEach(row => {
        const rowText = row.textContent || '';
        const deobfuscated = deobfuscateEmail(rowText);
        const emailMatches = deobfuscated.match(EMAIL_REGEX) || [];

        emailMatches.forEach(email => {
          email = email.toLowerCase();
          if (seen.has(email) || !isValidEmail(email)) return;
          seen.add(email);

          const cells = row.querySelectorAll('td, th');
          let name = '';
          let jobTitle = '';

          cells.forEach((cell, index) => {
            const cellText = cleanText(cell.textContent);

            // First cell often contains name
            if (index === 0 && !cellText.includes('@') && /^[A-Za-z\s\.\-']{2,60}$/.test(cellText)) {
              name = cellText;
            }

            // Look for job title
            if (!jobTitle) {
              for (const pattern of JOB_TITLE_PATTERNS) {
                if (pattern.test(cellText)) {
                  jobTitle = cellText;
                  break;
                }
              }
            }
          });

          results.push({
            name: name,
            email: email,
            jobTitle: jobTitle,
            source: 'table'
          });
        });
      });
    });

    return results;
  }

  /**
   * Fallback: Extract emails from entire page with best-effort context
   */
  function extractFromPage() {
    const results = [];
    const seen = new Set();
    const pageText = document.body.innerText || '';
    const deobfuscated = deobfuscateEmail(pageText);
    const emailMatches = deobfuscated.match(EMAIL_REGEX) || [];

    emailMatches.forEach(email => {
      email = email.toLowerCase();
      if (seen.has(email) || !isValidEmail(email)) return;
      seen.add(email);

      results.push({
        name: '',
        email: email,
        jobTitle: '',
        source: 'page-scan'
      });
    });

    return results;
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
      'noreply', 'no-reply', 'donotreply'
    ];

    return !blacklist.some(bl => email.includes(bl));
  }

  /**
   * Main extraction function - returns array of {name, email, jobTitle}
   */
  function extractAllWithContext(deepScan = false) {
    const allResults = [];
    const seenEmails = new Set();

    // Priority order: staff cards, mailto links, tables, page scan
    const sources = [
      extractFromStaffCards(),
      extractFromMailtoLinks(),
      extractFromTables()
    ];

    if (deepScan) {
      sources.push(extractFromPage());
    }

    // Merge results, preferring entries with more context
    sources.forEach(sourceResults => {
      sourceResults.forEach(result => {
        if (seenEmails.has(result.email)) {
          // Update existing entry if new one has more info
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
    const results = extractAllWithContext(deepScan);
    return results.map(r => r.email);
  }

  // Listen for messages from popup
  chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'extractEmails') {
      const emails = extractAllEmails(request.deepScan || false);
      sendResponse({ emails: emails, count: emails.length });
    } else if (request.action === 'extractWithContext') {
      const results = extractAllWithContext(request.deepScan || false);
      sendResponse({ results: results, count: results.length });
    } else if (request.action === 'detectStaffPage') {
      const detection = detectStaffPage();
      sendResponse(detection);
    } else if (request.action === 'ping') {
      sendResponse({ status: 'ready' });
    }
    return true;
  });

  // Auto-detect and notify if on staff page
  chrome.storage.sync.get(['autoDetect'], (result) => {
    if (result.autoDetect) {
      const detection = detectStaffPage();
      if (detection.isStaffPage) {
        chrome.runtime.sendMessage({
          action: 'staffPageDetected',
          ...detection
        });
      }
    }
  });

  console.log('📧 Email Extractor content script loaded (v2 with context)');
})();
