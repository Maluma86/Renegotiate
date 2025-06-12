// Renegotiation Calculator - Real-time percentage discount calculations
document.addEventListener('DOMContentLoaded', function() {
  
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
    // Extract number from currency format (e.g., "€1,234.56" -> 1234.56)
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
    
    // Calculate the discounted prices
    const targetPrice = calculateDiscountedPrice(currentPrice, targetDiscount);
    const minPrice = calculateDiscountedPrice(currentPrice, minDiscount);
    
    // Determine which is lower and higher for proper range display
    const lowerPrice = Math.min(targetPrice, minPrice);
    const higherPrice = Math.max(targetPrice, minPrice);
    
    // Update the display
    calculatedRangeElement.textContent = `${formatCurrency(lowerPrice)} - ${formatCurrency(higherPrice)}`;
    
    // Add visual feedback classes
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
    
    // Ensure percentage is reasonable (0-100%)
    if (value < 0) {
      input.value = 0;
    } else if (value > 100) {
      input.value = 100;
    }
    
    // Add visual feedback for input state
    if (value > 0) {
      input.classList.add('has-value');
    } else {
      input.classList.remove('has-value');
    }
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
  
  // Event listeners for better UX
  targetDiscountInput.addEventListener('focus', function() {
    this.select(); // Select all text on focus
  });
  
  minDiscountInput.addEventListener('focus', function() {
    this.select(); // Select all text on focus
  });
  
  // Initialize display on page load
  updateCalculatedRange();
  
  console.log('Renegotiation Calculator initialized successfully');
});
