// Content Script - Runs on web pages to extract emails

(function() {
  'use strict';

  // Email regex pattern - comprehensive
  const EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;

  // Common obfuscation patterns schools use
  const OBFUSCATION_PATTERNS = [
    /\[at\]/gi,
    /\(at\)/gi,
    /\s+at\s+/gi,
    /\[dot\]/gi,
    /\(dot\)/gi,
    /\s+dot\s+/gi
  ];

  /**
   * Deobfuscate email addresses
   */
  function deobfuscateEmail(text) {
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
   * Extract emails from mailto: links
   */
  function extractFromMailtoLinks() {
    const emails = new Set();
    const links = document.querySelectorAll('a[href^="mailto:"]');

    links.forEach(link => {
      const href = link.getAttribute('href');
      if (href) {
        // Extract email from mailto:email@domain.com?subject=...
        const email = href.replace('mailto:', '').split('?')[0].toLowerCase().trim();
        if (email && EMAIL_REGEX.test(email)) {
          emails.add(email);
        }
      }
    });

    return emails;
  }

  /**
   * Extract emails from data attributes (common in school sites)
   */
  function extractFromDataAttributes() {
    const emails = new Set();
    const allElements = document.querySelectorAll('*');

    allElements.forEach(el => {
      // Check all data attributes
      for (const attr of el.attributes) {
        if (attr.name.startsWith('data-')) {
          const value = attr.value;
          const matches = value.match(EMAIL_REGEX);
          if (matches) {
            matches.forEach(email => emails.add(email.toLowerCase()));
          }
        }
      }

      // Check common school-specific attributes
      const emailAttrs = ['data-email', 'data-mail', 'data-contact', 'data-address'];
      emailAttrs.forEach(attrName => {
        const value = el.getAttribute(attrName);
        if (value) {
          const deobfuscated = deobfuscateEmail(value);
          const matches = deobfuscated.match(EMAIL_REGEX);
          if (matches) {
            matches.forEach(email => emails.add(email.toLowerCase()));
          }
        }
      });
    });

    return emails;
  }

  /**
   * Extract emails from visible text content
   */
  function extractFromTextContent() {
    const emails = new Set();

    // Get all text content
    const textContent = document.body.innerText || '';

    // First try direct email matches
    const directMatches = textContent.match(EMAIL_REGEX);
    if (directMatches) {
      directMatches.forEach(email => emails.add(email.toLowerCase()));
    }

    // Try deobfuscated content
    const deobfuscated = deobfuscateEmail(textContent);
    const obfuscatedMatches = deobfuscated.match(EMAIL_REGEX);
    if (obfuscatedMatches) {
      obfuscatedMatches.forEach(email => emails.add(email.toLowerCase()));
    }

    return emails;
  }

  /**
   * Extract emails from onclick/onmouseover handlers (school sites often hide emails here)
   */
  function extractFromEventHandlers() {
    const emails = new Set();
    const elementsWithHandlers = document.querySelectorAll('[onclick], [onmouseover], [onmouseenter]');

    elementsWithHandlers.forEach(el => {
      ['onclick', 'onmouseover', 'onmouseenter'].forEach(handler => {
        const value = el.getAttribute(handler);
        if (value) {
          const matches = value.match(EMAIL_REGEX);
          if (matches) {
            matches.forEach(email => emails.add(email.toLowerCase()));
          }
        }
      });
    });

    return emails;
  }

  /**
   * Extract emails from hidden elements and title/alt attributes
   */
  function extractFromHiddenContent() {
    const emails = new Set();

    // Check title and alt attributes
    const elementsWithTitles = document.querySelectorAll('[title], [alt]');
    elementsWithTitles.forEach(el => {
      const title = el.getAttribute('title') || '';
      const alt = el.getAttribute('alt') || '';

      [title, alt].forEach(text => {
        const deobfuscated = deobfuscateEmail(text);
        const matches = deobfuscated.match(EMAIL_REGEX);
        if (matches) {
          matches.forEach(email => emails.add(email.toLowerCase()));
        }
      });
    });

    // Check aria-label
    const ariaElements = document.querySelectorAll('[aria-label]');
    ariaElements.forEach(el => {
      const label = el.getAttribute('aria-label') || '';
      const deobfuscated = deobfuscateEmail(label);
      const matches = deobfuscated.match(EMAIL_REGEX);
      if (matches) {
        matches.forEach(email => emails.add(email.toLowerCase()));
      }
    });

    return emails;
  }

  /**
   * Extract emails from inline scripts (some sites store data here)
   */
  function extractFromScripts() {
    const emails = new Set();
    const scripts = document.querySelectorAll('script:not([src])');

    scripts.forEach(script => {
      const content = script.textContent || '';
      const matches = content.match(EMAIL_REGEX);
      if (matches) {
        matches.forEach(email => {
          // Filter out common false positives from scripts
          if (!email.includes('example.com') &&
              !email.includes('test.com') &&
              !email.includes('@2x') &&
              !email.includes('@media')) {
            emails.add(email.toLowerCase());
          }
        });
      }
    });

    return emails;
  }

  /**
   * Deep scan - look for emails in staff card patterns
   */
  function deepScanStaffCards() {
    const emails = new Set();

    // Common staff card selectors used by schools
    const cardSelectors = [
      '.staff-card', '.staff-member', '.team-member', '.faculty-member',
      '.employee-card', '.person-card', '.profile-card', '.member-card',
      '[class*="staff"]', '[class*="faculty"]', '[class*="teacher"]',
      '[class*="employee"]', '[class*="team-member"]', '[class*="personnel"]',
      '.card', '.profile', '.bio', '.directory-item'
    ];

    cardSelectors.forEach(selector => {
      try {
        const cards = document.querySelectorAll(selector);
        cards.forEach(card => {
          // Get all content including hidden elements
          const html = card.innerHTML;
          const matches = html.match(EMAIL_REGEX);
          if (matches) {
            matches.forEach(email => emails.add(email.toLowerCase()));
          }

          // Check for encoded emails
          const decodedHtml = decodeURIComponent(html);
          const decodedMatches = decodedHtml.match(EMAIL_REGEX);
          if (decodedMatches) {
            decodedMatches.forEach(email => emails.add(email.toLowerCase()));
          }
        });
      } catch (e) {
        // Selector might be invalid, skip
      }
    });

    return emails;
  }

  /**
   * Extract emails from image elements (check data attributes and nearby text)
   */
  function extractFromImages() {
    const emails = new Set();
    const images = document.querySelectorAll('img');

    images.forEach(img => {
      // Check image's data attributes
      for (const attr of img.attributes) {
        const value = attr.value;
        const matches = value.match(EMAIL_REGEX);
        if (matches) {
          matches.forEach(email => emails.add(email.toLowerCase()));
        }
      }

      // Check parent element
      const parent = img.parentElement;
      if (parent) {
        const parentHtml = parent.innerHTML;
        const matches = parentHtml.match(EMAIL_REGEX);
        if (matches) {
          matches.forEach(email => emails.add(email.toLowerCase()));
        }

        // Check for mailto links in parent
        const mailtoLinks = parent.querySelectorAll('a[href^="mailto:"]');
        mailtoLinks.forEach(link => {
          const email = link.getAttribute('href').replace('mailto:', '').split('?')[0];
          if (email) emails.add(email.toLowerCase());
        });
      }
    });

    return emails;
  }

  /**
   * Main extraction function - combines all methods
   */
  function extractAllEmails(deepScan = false) {
    const allEmails = new Set();

    // Basic extraction methods
    const sources = [
      extractFromMailtoLinks(),
      extractFromDataAttributes(),
      extractFromTextContent(),
      extractFromEventHandlers(),
      extractFromHiddenContent()
    ];

    // Deep scan methods (more intensive)
    if (deepScan) {
      sources.push(extractFromScripts());
      sources.push(deepScanStaffCards());
      sources.push(extractFromImages());
    }

    // Combine all results
    sources.forEach(emailSet => {
      emailSet.forEach(email => allEmails.add(email));
    });

    // Filter and validate emails
    const validEmails = Array.from(allEmails).filter(email => {
      // Basic validation
      if (!email || email.length < 5) return false;
      if (!email.includes('@')) return false;
      if (!email.includes('.')) return false;

      // Filter out common false positives
      const blacklist = [
        'example.com', 'test.com', 'email.com', 'domain.com',
        'your-email', 'youremail', 'name@', 'user@',
        '@2x.', '@3x.', '@media', '.png', '.jpg', '.gif'
      ];

      return !blacklist.some(bl => email.includes(bl));
    });

    return validEmails.sort();
  }

  /**
   * Get email with associated name if possible
   */
  function extractEmailsWithContext() {
    const results = [];

    // Look for staff cards with name + email
    const cardSelectors = [
      '.staff-card', '.staff-member', '.team-member', '.profile-card',
      '[class*="staff"]', '[class*="employee"]', '.card'
    ];

    cardSelectors.forEach(selector => {
      try {
        document.querySelectorAll(selector).forEach(card => {
          const emailMatch = card.innerHTML.match(EMAIL_REGEX);
          if (emailMatch) {
            // Try to find associated name
            const nameElement = card.querySelector('h2, h3, h4, .name, .title, [class*="name"]');
            const name = nameElement ? nameElement.textContent.trim() : '';

            emailMatch.forEach(email => {
              results.push({
                email: email.toLowerCase(),
                name: name,
                source: 'staff-card'
              });
            });
          }
        });
      } catch (e) {}
    });

    return results;
  }

  // Listen for messages from popup
  chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'extractEmails') {
      const emails = extractAllEmails(request.deepScan || false);
      sendResponse({ emails: emails, count: emails.length });
    } else if (request.action === 'extractWithContext') {
      const results = extractEmailsWithContext();
      sendResponse({ results: results });
    } else if (request.action === 'ping') {
      sendResponse({ status: 'ready' });
    }
    return true; // Keep message channel open for async response
  });

  // Auto-extract on page load if enabled (can be toggled in settings)
  chrome.storage.sync.get(['autoExtract'], (result) => {
    if (result.autoExtract) {
      const emails = extractAllEmails(false);
      if (emails.length > 0) {
        chrome.runtime.sendMessage({
          action: 'emailsFound',
          emails: emails,
          url: window.location.href
        });
      }
    }
  });

  console.log('📧 Email Extractor content script loaded');
})();
