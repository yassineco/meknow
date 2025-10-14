document.addEventListener('DOMContentLoaded', function() {
  const productForm = document.querySelector('.product-form');
  const stickyBar = document.querySelector('.sticky-atc-bar');
  
  if (!productForm || !stickyBar) return;

  const observer = new IntersectionObserver(
    ([entry]) => {
      if (entry.isIntersecting) {
        stickyBar.classList.remove('sticky-atc-bar--visible');
      } else {
        stickyBar.classList.add('sticky-atc-bar--visible');
      }
    },
    {
      threshold: 0,
      rootMargin: '-80px'
    }
  );

  observer.observe(productForm);

  const stickyButton = stickyBar.querySelector('.sticky-atc-bar__button');
  if (stickyButton) {
    stickyButton.addEventListener('click', function(e) {
      e.preventDefault();
      productForm.scrollIntoView({ behavior: 'smooth', block: 'center' });
      
      setTimeout(() => {
        const submitButton = productForm.querySelector('[type="submit"]');
        if (submitButton) {
          submitButton.focus();
        }
      }, 500);
    });
  }
});
