import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ai-intelligence"
export default class extends Controller {
  static values = { renegotiationId: Number }

  connect() {
    console.log("🤖 AI Intelligence Controller connected for renegotiation", this.renegotiationIdValue)
    
    // Start the background job immediately when controller connects
    this.startProductIntelligence()
    
    // Start polling for results
    this.startPolling()
    
    // Set timeout for fallback
    this.setupTimeout()
  }

  disconnect() {
    console.log("🤖 AI Intelligence Controller disconnected")
    
    // Clean up any intervals or timeouts
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
    }
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  startProductIntelligence() {
    console.log("🚀 Starting product intelligence job for renegotiation", this.renegotiationIdValue)
    
    fetch(`/renegotiations/${this.renegotiationIdValue}/start_product_intelligence`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json'
      }
    })
    .then(response => {
      console.log("✅ Product intelligence job started successfully")
    })
    .catch(error => {
      console.error("❌ Error starting product intelligence:", error)
      this.showFallbackContent()
    })
  }

  startPolling() {
    console.log("📡 Starting status polling...")
    
    // Poll for results every 2 seconds
    this.pollInterval = setInterval(() => {
      this.checkProductIntelligenceStatus()
    }, 2000)
  }

  checkProductIntelligenceStatus() {
    fetch(`/renegotiations/${this.renegotiationIdValue}/product_intelligence_status`)
      .then(response => response.json())
      .then(data => {
        console.log("📊 Status check result:", data.status)
        
        if (data.status === 'completed') {
          console.log("🎉 AI analysis completed! Updating UI...")
          clearInterval(this.pollInterval)
          this.updateUIWithIntelligence(data.data)
        }
      })
      .catch(error => {
        console.error("❌ Error checking status:", error)
        clearInterval(this.pollInterval)
        this.showFallbackContent()
      })
  }

  setupTimeout() {
    // Timeout after 30 seconds - only if content hasn't loaded
    this.timeoutId = setTimeout(() => {
      clearInterval(this.pollInterval)
      
      // Only show fallback if AI content is still hidden (meaning it never loaded)
      const aiContent = document.getElementById('ai-content')
      if (aiContent && aiContent.style.display === 'none') {
        console.log("⏰ Timeout reached, showing fallback content")
        this.showFallbackContent()
      }
    }, 30000)
  }

  updateUIWithIntelligence(intelligence) {
    console.log("🔄 Updating UI with intelligence data:", Object.keys(intelligence))
    
    // Hide loading and show content
    const loadingElement = document.getElementById('ai-loading')
    const contentElement = document.getElementById('ai-content')
    
    if (loadingElement) loadingElement.style.display = 'none'
    if (contentElement) contentElement.style.display = 'block'

    // Update recommendation text
    this.updateRecommendation(intelligence.recommendation)
    
    // Update dashboard sections when data is available
    if (intelligence.ingredients) {
      this.updateIngredientAnalysis(intelligence.ingredients)
    }
    if (intelligence.price_drivers) {
      this.updatePriceDrivers(intelligence.price_drivers)
    }
    if (intelligence.forecast) {
      this.updateForecastChart(intelligence.forecast)
    }
    if (intelligence.risks) {
      this.updateRiskIntelligence(intelligence.risks)
    }
    if (intelligence.strategies) {
      this.updateStrategies(intelligence.strategies)
    }
    
    console.log("✅ UI update completed successfully")
  }

  updateRecommendation(recommendation) {
    const recommendationElement = document.getElementById('ai-recommendation-text')
    if (recommendationElement) {
      recommendationElement.innerText = recommendation || 'AI analysis completed successfully.'
    }
  }

  updateIngredientAnalysis(ingredients) {
    console.log("🧪 Updating ingredient analysis with", ingredients.length, "ingredients")
    
    const tbody = document.querySelector('.ingredient-analysis tbody')
    if (!tbody || !ingredients || !Array.isArray(ingredients)) return

    // Clear existing rows
    tbody.innerHTML = ''

    // Add new rows for each ingredient
    ingredients.forEach((ingredient, index) => {
      const row = document.createElement('tr')
      row.style.borderBottom = index === ingredients.length - 1 ? 'none' : '1px solid #1F2937'

      // Determine trend color and arrow
      let trendColor, trendArrow, trendSign
      if (ingredient.price_trend > 0) {
        trendColor = ingredient.price_trend > 10 ? '#EF4444' : '#FBBF24'
        trendArrow = '↑'
        trendSign = '+'
      } else if (ingredient.price_trend < 0) {
        trendColor = '#10B981'
        trendArrow = '↓'
        trendSign = ''
      } else {
        trendColor = '#6B7280'
        trendArrow = '→'
        trendSign = ''
      }

      // Determine risk level color
      let riskColor
      switch (ingredient.risk_level) {
        case 'HIGH': riskColor = '#EF4444'; break
        case 'MEDIUM': riskColor = '#FBBF24'; break
        case 'LOW': riskColor = '#10B981'; break
        default: riskColor = '#6B7280'
      }

      row.innerHTML = `
        <td style="padding: 1rem; color: #E5E4E2; font-weight: 500;">${ingredient.name}</td>
        <td style="text-align: center; padding: 1rem; color: #FF7518; font-weight: 700;">${ingredient.percentage}%</td>
        <td style="padding: 1rem; color: #E5E4E2;">${ingredient.origin}</td>
        <td style="text-align: center; padding: 1rem;">
          <span style="color: ${trendColor}; font-weight: 600;">${trendArrow} ${trendSign}${ingredient.price_trend}%</span>
        </td>
        <td style="text-align: right; padding: 1rem;">
          <span style="background: ${riskColor}; color: white; padding: 0.25rem 0.75rem; border-radius: 0.25rem; font-size: 0.875rem;">${ingredient.risk_level}</span>
        </td>
      `

      tbody.appendChild(row)
    })
  }

  updatePriceDrivers(priceDrivers) {
    console.log("📈 Updating price drivers with", priceDrivers.length, "drivers")
    
    const priceDriversList = document.querySelector('.price-drivers-list')
    if (!priceDriversList || !priceDrivers || !Array.isArray(priceDrivers)) return

    // Clear existing items
    priceDriversList.innerHTML = ''

    // Add new price drivers
    priceDrivers.forEach((driver, index) => {
      const listItem = document.createElement('li')
      listItem.style.cssText = `padding: 0.5rem 0; ${index === priceDrivers.length - 1 ? '' : 'border-bottom: 1px solid #1F2937;'}`

      // Determine color based on level
      let color
      switch (driver.level.toLowerCase()) {
        case 'high': color = '#EF4444'; break
        case 'low': color = '#10B981'; break
        default: color = '#FBBF24'
      }

      listItem.innerHTML = `
        <span style="color: ${color};">${driver.icon}</span>
        <span style="color: #E5E4E2; margin-left: 0.5rem;">${driver.description}</span>
      `

      priceDriversList.appendChild(listItem)
    })
  }

  updateForecastChart(forecastData) {
    console.log("📊 Updating forecast chart")
    
    if (!forecastData || !forecastData.periods) return

    const labelsContainer = document.getElementById('forecast-labels')
    const barsContainer = document.getElementById('forecast-bars')
    const titleElement = document.getElementById('forecast-title')
    const trendElement = document.getElementById('forecast-trend')

    // Update title if provided
    if (forecastData.title && titleElement) {
      titleElement.textContent = forecastData.title
    }

    // Clear existing content
    if (labelsContainer) labelsContainer.innerHTML = ''
    if (barsContainer) barsContainer.innerHTML = ''

    // Add new labels and bars
    forecastData.periods.forEach((period, index) => {
      // Add label
      if (labelsContainer) {
        const label = document.createElement('span')
        label.style.cssText = 'color: #9CA3AF; font-size: 0.75rem;'
        label.textContent = period.label
        labelsContainer.appendChild(label)
      }

      // Determine color based on trend
      let color = '#6B7280' // neutral
      if (period.trend > 0) color = period.trend > 10 ? '#EF4444' : '#FF7518' // red or orange for increases
      if (period.trend < 0) color = '#10B981' // green for decreases

      // Add bar
      if (barsContainer) {
        const bar = document.createElement('div')
        bar.className = 'forecast-bar'
        bar.style.cssText = `
          flex: 1;
          background: ${color};
          height: ${Math.max(10, Math.min(90, period.value))}%;
          opacity: 0.8;
          border-radius: 0.25rem 0.25rem 0 0;
          transition: all 0.3s ease;
        `
        bar.setAttribute('data-value', period.value)
        bar.setAttribute('data-period', period.label)
        bar.setAttribute('title', `${period.label}: ${period.trend > 0 ? '+' : ''}${period.trend}%`)
        barsContainer.appendChild(bar)
      }
    })

    // Update overall trend
    if (forecastData.overallTrend && trendElement) {
      const trendColor = forecastData.overallTrend.value > 0 ? '#EF4444' : '#10B981'
      trendElement.style.color = trendColor
      trendElement.textContent = `${forecastData.overallTrend.value > 0 ? '+' : ''}${forecastData.overallTrend.value}% ${forecastData.overallTrend.description}`
    }
  }

  updateRiskIntelligence(risks) {
    console.log("⚠️ Updating risk intelligence dashboard")
    
    if (!risks) return
    
    // Update each risk category
    this.updateRiskCategory('geopolitical', risks.geopolitical)
    this.updateRiskCategory('product-specific', risks.product_specific)
    this.updateRiskCategory('supply-chain', risks.supply_chain)
  }

  updateRiskCategory(categoryId, riskData) {
    if (!riskData) return
    
    const levelElement = document.getElementById(`${categoryId}-risk-level`)
    const sectionElement = document.getElementById(`${categoryId}-risk-section`)
    const itemsElement = document.getElementById(`${categoryId}-risk-items`)
    
    if (!levelElement || !sectionElement || !itemsElement) return
    
    // Update level and styling
    const level = riskData.level || 'MEDIUM'
    levelElement.textContent = level
    
    // Update colors based on level
    let bgColor, borderColor
    switch (level) {
      case 'HIGH':
        bgColor = '#EF4444'
        borderColor = '#EF4444'
        break
      case 'LOW':
        bgColor = '#10B981'
        borderColor = '#10B981'
        break
      default:
        bgColor = '#FBBF24'
        borderColor = '#FBBF24'
    }
    
    levelElement.style.background = bgColor
    sectionElement.style.borderTopColor = borderColor
    
    // Update risk items
    if (riskData.items && Array.isArray(riskData.items)) {
      itemsElement.innerHTML = ''
      riskData.items.forEach(item => {
        const li = document.createElement('li')
        li.style.padding = '0.375rem 0'
        li.textContent = `• ${item}`
        itemsElement.appendChild(li)
      })
    }
  }

  updateStrategies(strategiesData) {
    console.log("🎯 Updating negotiation strategies")
    
    if (!strategiesData) return
    
    const strategiesList = document.getElementById('negotiation-strategies-list')
    const proTipElement = document.getElementById('negotiation-pro-tip')
    
    // Update strategies list
    if (strategiesList && strategiesData.strategies && Array.isArray(strategiesData.strategies)) {
      strategiesList.innerHTML = ''
      
      strategiesData.strategies.forEach((strategy, index) => {
        const li = document.createElement('li')
        li.style.marginBottom = index === strategiesData.strategies.length - 1 ? '0' : '0.75rem'
        li.innerHTML = `<strong>${strategy.title}</strong> - ${strategy.description}`
        strategiesList.appendChild(li)
      })
    }
    
    // Update pro tip
    if (proTipElement && strategiesData.pro_tip) {
      proTipElement.innerHTML = `<em>💡 Pro tip: ${strategiesData.pro_tip}</em>`
    }
  }

  showFallbackContent() {
    console.log("⚠️ Showing fallback content")
    
    const loadingElement = document.getElementById('ai-loading')
    const contentElement = document.getElementById('ai-content')
    const recommendationElement = document.getElementById('ai-recommendation-text')
    
    if (loadingElement) loadingElement.style.display = 'none'
    if (contentElement) contentElement.style.display = 'block'
    if (recommendationElement) {
      recommendationElement.innerText = 'AI analysis is taking longer than expected. Please refresh the page to see updated insights.'
    }
  }
}