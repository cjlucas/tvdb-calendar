import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["input", "submit", "progress", "progressFill", "progressText", "result", "error", "calendarUrl", "copyButton", "errorMessage"]
  static outlets = []

  connect() {
    console.log("🚀 PinFormController: Successfully connected to form!")
    
    // Check which targets are available
    const availableTargets = []
    if (this.hasInputTarget) availableTargets.push("input")
    if (this.hasSubmitTarget) availableTargets.push("submit") 
    if (this.hasProgressTarget) availableTargets.push("progress")
    console.log("📋 Available targets:", availableTargets)
    
    try {
      this.cable = createConsumer()
      console.log("📡 ActionCable consumer created successfully")
      this.subscription = null
    } catch (error) {
      console.error("❌ Error creating ActionCable consumer:", error)
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  async submit(event) {
    console.log("PinFormController: Submit method called", event)
    event.preventDefault()
    
    const pin = this.inputTarget.value.trim()
    console.log("PinFormController: PIN entered:", pin)
    if (!pin) {
      this.showError("Please enter your TheTVDB PIN")
      return
    }

    // Reset UI state
    this.hideAllContainers()
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Processing..."

    try {
      const csrfToken = this.getCSRFToken()
      console.log("CSRF Token:", csrfToken)
      
      const response = await fetch("/users", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          user: { pin: pin }
        })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.message || data.errors?.join(", ") || "An error occurred")
        return
      }

      console.log("PinFormController: Server response", data)
      switch (data.status) {
        case "ready":
          console.log("PinFormController: User already synced, showing result")
          this.showResult(data.calendar_url)
          break
        case "syncing":
          console.log("PinFormController: User needs sync, starting progress display")
          this.showProgress()
          this.subscribeToSyncUpdates(data.user_id, data.calendar_url)
          break
        default:
          console.error("PinFormController: Unexpected status", data.status)
          this.showError("Unexpected response from server")
      }

    } catch (error) {
      console.error("Error:", error)
      this.showError("Failed to connect to server. Please try again.")
    } finally {
      this.submitTarget.disabled = false
      this.submitTarget.textContent = "Generate Calendar"
    }
  }

  subscribeToSyncUpdates(userId, calendarUrl) {
    console.log("PinFormController: Subscribing to sync updates for user", userId)
    
    if (this.subscription) {
      console.log("PinFormController: Unsubscribing from existing subscription")
      this.subscription.unsubscribe()
    }

    try {
      this.subscription = this.cable.subscriptions.create(
        { channel: "SyncChannel", user_id: userId },
        {
          received: (data) => {
            console.log("PinFormController: Received sync data", data)
            if (data.error) {
              this.showError(data.message)
              return
            }
            
            this.updateProgress(data.percentage, data.message)
            
            if (data.percentage >= 100) {
              console.log("PinFormController: Sync complete, showing result")
              setTimeout(() => {
                this.showResult(calendarUrl)
              }, 1000)
            }
          },
          connected: () => {
            console.log("PinFormController: ✅ Connected to sync channel for user", userId)
          },
          disconnected: () => {
            console.log("PinFormController: ❌ Disconnected from sync channel")
          },
          rejected: () => {
            console.error("PinFormController: ❌ Subscription rejected")
          }
        }
      )
      console.log("PinFormController: Subscription created", this.subscription)
    } catch (error) {
      console.error("PinFormController: Error creating subscription", error)
    }
  }

  updateProgress(percentage, message) {
    if (this.hasProgressFillTarget) {
      this.progressFillTarget.style.width = `${percentage}%`
    }
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = message
    }
  }

  showProgress() {
    this.hideAllContainers()
    if (this.hasProgressTarget) {
      this.progressTarget.style.display = "block"
      this.updateProgress(0, "Starting sync...")
    }
  }

  showResult(calendarUrl) {
    this.hideAllContainers()
    if (this.hasCalendarUrlTarget) {
      this.calendarUrlTarget.value = calendarUrl
    }
    if (this.hasResultTarget) {
      this.resultTarget.style.display = "block"
    }
    
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  showError(message) {
    this.hideAllContainers()
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
    }
    if (this.hasErrorTarget) {
      this.errorTarget.style.display = "block"
    }
  }

  hideAllContainers() {
    if (this.hasProgressTarget) this.progressTarget.style.display = "none"
    if (this.hasResultTarget) this.resultTarget.style.display = "none"
    if (this.hasErrorTarget) this.errorTarget.style.display = "none"
  }

  copy(event) {
    event.preventDefault()
    if (this.hasCalendarUrlTarget) {
      this.calendarUrlTarget.select()
      this.calendarUrlTarget.setSelectionRange(0, 99999) // For mobile devices

      try {
        document.execCommand("copy")
        if (this.hasCopyButtonTarget) {
          const originalText = this.copyButtonTarget.textContent
          this.copyButtonTarget.textContent = "Copied!"
          
          setTimeout(() => {
            this.copyButtonTarget.textContent = originalText
          }, 2000)
        }
      } catch (err) {
        console.error("Failed to copy text: ", err)
      }
    }
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute("content") : ""
  }
}