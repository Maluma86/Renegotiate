// Renegotiation Calculator - Real-time percentage discount calculations
document.addEventListener('turbo:load', function() {
  // Get DOM elements
  const currentPriceElement = document.getElementById('current-price');
  const targetDiscountInput = document.getElementById('target-discount');
  const minDiscountInput = document.getElementById('min-discount');
  const calculatedRangeElement = document.getElementById('calculated-range');

  // Check if we're on the renegotiation page with these elements
  if (!currentPriceElement || !targetDiscountInput || !minDiscountInput || !calculatedRangeElement) {
    return; // Exit if elements don't exist on this page
  }

  // Function to get current price as number
  function getCurrentPrice() {
    const priceText = currentPriceElement.textContent || currentPriceElement.innerText;
    const numericValue = priceText.replace(/[€$,]/g, '').trim();
    return parseFloat(numericValue) || 0;
  }

  // Function to calculate discounted price
  function calculateDiscountedPrice(originalPrice, discountPercentage) {
    if (!discountPercentage || discountPercentage < 0) return originalPrice;
    const discountAmount = originalPrice * (discountPercentage / 100);
    return originalPrice - discountAmount;
  }

  // Function to format currency
  function formatCurrency(amount) {
    return new Intl.NumberFormat('en-EU', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount);
  }

  // Function to update the calculated range display
  function updateCalculatedRange() {
    const currentPrice = getCurrentPrice();
    const targetDiscount = parseFloat(targetDiscountInput.value) || 0;
    const minDiscount = parseFloat(minDiscountInput.value) || 0;
    const targetPrice = calculateDiscountedPrice(currentPrice, targetDiscount);
    const minPrice = calculateDiscountedPrice(currentPrice, minDiscount);
    const lowerPrice = Math.min(targetPrice, minPrice);
    const higherPrice = Math.max(targetPrice, minPrice);

    calculatedRangeElement.textContent = `${formatCurrency(lowerPrice)} - ${formatCurrency(higherPrice)}`;

    calculatedRangeElement.classList.remove('calculation-empty');
    if (targetDiscount > 0 || minDiscount > 0) {
      calculatedRangeElement.classList.add('calculation-active');
    } else {
      calculatedRangeElement.classList.remove('calculation-active');
    }
  }

  // Function to validate input values
  function validateInput(input) {
    const value = parseFloat(input.value);
    if (value < 0) input.value = 0;
    else if (value > 100) input.value = 100;

    if (value > 0) input.classList.add('has-value');
    else input.classList.remove('has-value');
  }

  // Event listeners for real-time calculation
  targetDiscountInput.addEventListener('input', function() {
    validateInput(this);
    updateCalculatedRange();
  });
  minDiscountInput.addEventListener('input', function() {
    validateInput(this);
    updateCalculatedRange();
  });
  targetDiscountInput.addEventListener('focus', function() { this.select(); });
  minDiscountInput.addEventListener('focus', function() { this.select(); });

  // Initialize display on page load
  updateCalculatedRange();

  // === CUSTOM ARROW BUTTONS FUNCTIONALITY ===
  const arrowButtons = document.querySelectorAll('.arrow-btn');
  arrowButtons.forEach(button => {
    button.addEventListener('click', function() {
      const targetId = this.getAttribute('data-target');
      const targetInput = document.getElementById(targetId);
      const isUp = this.classList.contains('arrow-up');
      if (targetInput && !targetInput.disabled) {
        const currentValue = parseFloat(targetInput.value) || 0;
        const step = parseFloat(targetInput.step) || 0.5;
        const newValue = isUp ? currentValue + step : Math.max(0, currentValue - step);
        targetInput.value = Math.min(100, Math.max(0, newValue));
        targetInput.dispatchEvent(new Event('input', { bubbles: true }));
        targetInput.focus();
      }
    });
  });

  function updateArrowButtonStates() {
    [targetDiscountInput, minDiscountInput].forEach(input => {
      const inputId = input.id;
      const upButton = document.querySelector(`[data-target="${inputId}"].arrow-up`);
      const downButton = document.querySelector(`[data-target="${inputId}"].arrow-down`);
      if (upButton && downButton) {
        upButton.disabled = input.disabled;
        downButton.disabled = input.disabled;
      }
    });
  }

  updateArrowButtonStates();

  // === AJAX DISCOUNT TARGETS FUNCTIONALITY ===
  const discountTargetsForm = document.getElementById('discount-targets-form');
  const saveTargetsBtn = document.getElementById('save-targets-btn');
  const newTargetsBtn = document.getElementById('new-targets-btn');
  const loadingMessage = document.getElementById('loading-message');
  const successMessage = document.getElementById('success-message');
  const errorMessage = document.getElementById('error-message');

  if (discountTargetsForm) {
    discountTargetsForm.addEventListener('submit', function(e) {
      e.preventDefault(); // Prevent normal form submission
      submitDiscountTargets();
    });
  }

  // ===== UNLOCK VIA AJAX: The important change! =====
  if (newTargetsBtn) {
    newTargetsBtn.addEventListener('click', function() {
      // Read the unlock URL from the button's data attribute
      const unlockUrl = newTargetsBtn.dataset.unlockUrl;
      if (!unlockUrl) {
        alert("Unlock URL missing.");
        return;
      }
      // POST AJAX to unlock targets
      fetch(unlockUrl, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          unlockTargets(); // Unlock the UI
        } else {
          showErrorMessage("Failed to unlock targets.");
        }
      })
      .catch(() => showErrorMessage("Failed to unlock targets."));
    });
  }

  // ================================================

  // Function to submit discount targets via AJAX
  function submitDiscountTargets() {
    const formData = new FormData(discountTargetsForm);
    showLoadingState();
    fetch(discountTargetsForm.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        handleSaveSuccess(data);
      } else {
        handleSaveError(data.error);
      }
    })
    .catch(error => {
      handleSaveError('Network error. Please try again.');
      console.error('AJAX Error:', error);
    });
  }

  // Handle successful save
  function handleSaveSuccess(data) {
    hideLoadingState();
    showSuccessMessage(data.message);
    lockTargets();
  }
  function handleSaveError(errorMessage) {
    hideLoadingState();
    showErrorMessage(errorMessage);
  }
  function lockTargets() {
    targetDiscountInput.disabled = true;
    minDiscountInput.disabled = true;
    if (saveTargetsBtn) saveTargetsBtn.style.display = 'none';
    const newTargetsSection = document.querySelector('.new-targets-section');
    if (newTargetsSection) newTargetsSection.style.display = 'inline-block';
    updateArrowButtonStates();
  }
  function unlockTargets() {
    targetDiscountInput.disabled = false;
    minDiscountInput.disabled = false;
    const newTargetsSection = document.querySelector('.new-targets-section');
    if (newTargetsSection) newTargetsSection.style.display = 'none';
    if (saveTargetsBtn) saveTargetsBtn.style.display = 'inline-block';
    updateArrowButtonStates();
    clearMessages();
  }
  function showLoadingState() {
    clearMessages();
    if (loadingMessage) loadingMessage.style.display = 'block';
    if (saveTargetsBtn) saveTargetsBtn.disabled = true;
  }
  function hideLoadingState() {
    if (loadingMessage) loadingMessage.style.display = 'none';
    if (saveTargetsBtn) saveTargetsBtn.disabled = false;
  }
  function showSuccessMessage(message) {
    if (successMessage) {
      successMessage.textContent = message;
      successMessage.style.display = 'inline-block';
    }
  }
  function showErrorMessage(message) {
    if (errorMessage) {
      errorMessage.textContent = message;
      errorMessage.style.display = 'block';
    }
  }
  function clearMessages() {
    if (loadingMessage) loadingMessage.style.display = 'none';
    if (successMessage) successMessage.style.display = 'none';
    if (errorMessage) errorMessage.style.display = 'none';
  }
});
