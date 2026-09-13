document.addEventListener('DOMContentLoaded', () => {
  // Setup copy buttons
  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const code = btn.getAttribute('data-code');
      if (code) {
        navigator.clipboard.writeText(code).then(() => {
          const originalText = btn.textContent;
          btn.textContent = 'Copied!';
          btn.style.color = '#12c7b3';
          setTimeout(() => {
            btn.textContent = originalText;
            btn.style.color = '';
          }, 2000);
        });
      }
    });
  });

  // Mobile navigation drawer toggle
  const navToggle = document.getElementById('nav-toggle');
  const navMenu = document.getElementById('nav-menu');

  if (navToggle && navMenu) {
    navToggle.addEventListener('click', (e) => {
      e.stopPropagation();
      const isOpen = navMenu.classList.toggle('open');
      navToggle.classList.toggle('open');
      navToggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    });

    // Close when clicking any nav link
    navMenu.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navMenu.classList.remove('open');
        navToggle.classList.remove('open');
        navToggle.setAttribute('aria-expanded', 'false');
      });
    });

    // Close when clicking outside
    document.addEventListener('click', (e) => {
      if (!navMenu.contains(e.target) && !navToggle.contains(e.target) && navMenu.classList.contains('open')) {
        navMenu.classList.remove('open');
        navToggle.classList.remove('open');
        navToggle.setAttribute('aria-expanded', 'false');
      }
    });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && navMenu.classList.contains('open')) {
        navMenu.classList.remove('open');
        navToggle.classList.remove('open');
        navToggle.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // Sidebar active state highlight on scroll
  const sections = document.querySelectorAll('section[id], div[id]');
  const navLinks = document.querySelectorAll('.guide-menu a');

  window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(section => {
      const sectionTop = section.offsetTop - 120;
      if (pageYOffset >= sectionTop) {
        current = section.getAttribute('id');
      }
    });

    navLinks.forEach(link => {
      link.classList.remove('active');
      if (link.getAttribute('href') === `#${current}`) {
        link.classList.add('active');
      }
    });
  });

  // Hero Mockup interactive range switcher
  const rangeBtns = document.querySelectorAll('.mockup-range-pill');
  const chartPath = document.querySelector('.mockup-dynamic-path');
  const chartFill = document.querySelector('.mockup-dynamic-fill');
  const rateValue = document.querySelector('.spotlight-value');
  const rateDelta = document.querySelector('.spotlight-delta');

  const presets = {
    '1Y': {
      rate: '6.76%',
      delta: '+0.05% vs prior wk',
      path: 'M 10 50 Q 70 30 140 45 T 280 15',
      fill: 'M 10 50 Q 70 30 140 45 T 280 15 L 280 65 L 10 65 Z'
    },
    '5Y': {
      rate: '6.76%',
      delta: '+3.88% vs 2021 low',
      path: 'M 10 60 Q 60 55 120 20 T 280 15',
      fill: 'M 10 60 Q 60 55 120 20 T 280 15 L 280 65 L 10 65 Z'
    },
    'Max': {
      rate: '6.76%',
      delta: '1971–2026 (Peak 18.63%)',
      path: 'M 10 40 Q 50 10 90 20 T 180 50 T 280 15',
      fill: 'M 10 40 Q 50 10 90 20 T 180 50 T 280 15 L 280 65 L 10 65 Z'
    }
  };

  rangeBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const range = btn.textContent.trim();
      if (presets[range]) {
        rangeBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        if (rateValue) rateValue.textContent = presets[range].rate;
        if (rateDelta) rateDelta.textContent = presets[range].delta;
        if (chartPath) chartPath.setAttribute('d', presets[range].path);
        if (chartFill) chartFill.setAttribute('d', presets[range].fill);
      }
    });
  });

  // Showcase tabs switcher
  const tabs = document.querySelectorAll('.showcase-tab');
  const items = document.querySelectorAll('.showcase-item');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const target = tab.getAttribute('data-target');
      tabs.forEach(t => t.classList.remove('active'));
      items.forEach(item => item.classList.remove('active'));

      tab.classList.add('active');
      const activeItem = document.getElementById(target);
      if (activeItem) {
        activeItem.classList.add('active');
      }
    });
  });
});
