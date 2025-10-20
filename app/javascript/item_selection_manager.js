// Persistent Item Selection Manager for Print Queue
class ItemSelectionManager {
  constructor() {
    this.storageKey = 'frozen_inventory_print_selection';
    this.copyQuantitiesKey = 'frozen_inventory_copy_quantities';
    this.selectedItems = [];
    this.copyQuantities = {};
    this.loadSelection();
    this.initializeEventListeners();
  }

  loadSelection() {
    try {
      const storedItems = localStorage.getItem(this.storageKey);
      const storedCopies = localStorage.getItem(this.copyQuantitiesKey);

      this.selectedItems = storedItems ? JSON.parse(storedItems) : [];
      this.copyQuantities = storedCopies ? JSON.parse(storedCopies) : {};
    } catch (e) {
      console.warn('Failed to load selection from localStorage:', e);
      this.selectedItems = [];
      this.copyQuantities = {};
    }

    this.updateUI();
  }

  saveSelection() {
    try {
      localStorage.setItem(this.storageKey, JSON.stringify(this.selectedItems));
      localStorage.setItem(this.copyQuantitiesKey, JSON.stringify(this.copyQuantities));
    } catch (e) {
      console.warn('Failed to save selection to localStorage:', e);
    }
  }

  toggleItem(itemId) {
    itemId = parseInt(itemId);
    const index = this.selectedItems.indexOf(itemId);

    if (index > -1) {
      this.selectedItems.splice(index, 1);
      delete this.copyQuantities[itemId];
    } else {
      this.selectedItems.push(itemId);
      this.copyQuantities[itemId] = 1; // Default to 1 copy
    }

    this.saveSelection();
    this.updateUI();
  }

  setCopyQuantity(itemId, quantity) {
    itemId = parseInt(itemId);
    quantity = parseInt(quantity) || 1;

    if (this.selectedItems.includes(itemId)) {
      this.copyQuantities[itemId] = quantity;
      this.saveSelection();
      this.updateFloatingCounter();
    }
  }

  clearSelection() {
    this.selectedItems = [];
    this.copyQuantities = {};
    localStorage.removeItem(this.storageKey);
    localStorage.removeItem(this.copyQuantitiesKey);
    this.updateUI();
  }

  selectAll() {
    const allCheckboxes = document.querySelectorAll('.item-checkbox');
    allCheckboxes.forEach(checkbox => {
      const itemId = parseInt(checkbox.value);
      if (!this.selectedItems.includes(itemId)) {
        this.selectedItems.push(itemId);
        this.copyQuantities[itemId] = 1;
      }
    });
    this.saveSelection();
    this.updateUI();
  }

  deselectAll() {
    const visibleCheckboxes = document.querySelectorAll('.item-checkbox');
    const visibleItemIds = Array.from(visibleCheckboxes).map(cb => parseInt(cb.value));

    // Remove only visible items from selection
    this.selectedItems = this.selectedItems.filter(id => !visibleItemIds.includes(id));
    visibleItemIds.forEach(id => delete this.copyQuantities[id]);

    this.saveSelection();
    this.updateUI();
  }

  updateUI() {
    this.updateCheckboxes();
    this.updateCopyInputs();
    this.updateSelectAllCheckbox();
    this.updateFloatingCounter();
  }

  updateCheckboxes() {
    document.querySelectorAll('.item-checkbox').forEach(checkbox => {
      const itemId = parseInt(checkbox.value);
      checkbox.checked = this.selectedItems.includes(itemId);
    });
  }

  updateCopyInputs() {
    document.querySelectorAll('.copy-quantity-input').forEach(input => {
      const itemId = parseInt(input.id.replace('copies_', ''));
      const isSelected = this.selectedItems.includes(itemId);

      input.disabled = !isSelected;
      if (isSelected && this.copyQuantities[itemId]) {
        input.value = this.copyQuantities[itemId];
      }
    });
  }

  updateSelectAllCheckbox() {
    const selectAllCheckbox = document.getElementById('select-all');
    if (!selectAllCheckbox) return;

    const visibleCheckboxes = document.querySelectorAll('.item-checkbox');
    const visibleItemIds = Array.from(visibleCheckboxes).map(cb => parseInt(cb.value));
    const selectedVisibleItems = visibleItemIds.filter(id => this.selectedItems.includes(id));

    if (visibleItemIds.length === 0) {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = false;
    } else if (selectedVisibleItems.length === visibleItemIds.length) {
      selectAllCheckbox.checked = true;
      selectAllCheckbox.indeterminate = false;
    } else if (selectedVisibleItems.length > 0) {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = true;
    } else {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = false;
    }
  }

  updateFloatingCounter() {
    this.updateFloatingCounterDisplay();
    this.updatePrintButton();
  }

  updateFloatingCounterDisplay() {
    const floatingCounter = document.getElementById('floating-selection-counter');
    const count = this.selectedItems.length;

    if (count > 0) {
      if (floatingCounter) {
        floatingCounter.style.display = 'block';
        const totalCopies = Object.values(this.copyQuantities).reduce((sum, qty) => sum + qty, 0);
        const selectionText = document.getElementById('floating-selection-text');
        if (selectionText) {
          selectionText.textContent = `${count} item${count !== 1 ? 's' : ''} selected (${totalCopies} total copies)`;
        }
      }
    } else {
      if (floatingCounter) {
        floatingCounter.style.display = 'none';
      }
    }
  }

  updatePrintButton() {
    const printButton = document.getElementById('print-selected-btn');
    if (!printButton) return;

    const count = this.selectedItems.length;

    if (count > 0) {
      printButton.disabled = false;
      const totalCopies = Object.values(this.copyQuantities).reduce((sum, qty) => sum + qty, 0);
      printButton.textContent = `🖨️ Print ${totalCopies} label${totalCopies !== 1 ? 's' : ''} (${count} item${count !== 1 ? 's' : ''})`;
    } else {
      printButton.disabled = true;
      printButton.textContent = '🖨️ Print Selected';
    }
  }

  submitPrintForm() {
    const form = document.getElementById('barcode-print-form');
    if (!form) return;

    // Clear existing hidden inputs
    form.querySelectorAll('.persistent-selection-input').forEach(input => input.remove());

    // Add hidden inputs for selected items
    this.selectedItems.forEach(itemId => {
      const itemInput = document.createElement('input');
      itemInput.type = 'hidden';
      itemInput.name = 'item_ids[]';
      itemInput.value = itemId;
      itemInput.className = 'persistent-selection-input';
      form.appendChild(itemInput);

      const copyInput = document.createElement('input');
      copyInput.type = 'hidden';
      copyInput.name = `copies[${itemId}]`;
      copyInput.value = this.copyQuantities[itemId] || 1;
      copyInput.className = 'persistent-selection-input';
      form.appendChild(copyInput);
    });

    form.submit();
  }

  initializeEventListeners() {
    // Handle checkbox changes
    document.addEventListener('change', (e) => {
      if (e.target.matches('.item-checkbox')) {
        this.toggleItem(e.target.value);
      } else if (e.target.matches('.copy-quantity-input')) {
        const itemId = parseInt(e.target.id.replace('copies_', ''));
        this.setCopyQuantity(itemId, e.target.value);
      } else if (e.target.id === 'select-all') {
        if (e.target.checked) {
          this.selectAll();
        } else {
          this.deselectAll();
        }
      }
    });

    // Handle print button click
    document.addEventListener('click', (e) => {
      if (e.target.id === 'print-selected-btn') {
        e.preventDefault();
        this.submitPrintForm();
      } else if (e.target.id === 'floating-print-btn') {
        e.preventDefault();
        this.submitPrintForm();
      } else if (e.target.id === 'floating-clear-btn') {
        e.preventDefault();
        this.clearSelection();
      }
    });
  }

  // Public methods for external use
  getSelectionCount() {
    return this.selectedItems.length;
  }

  getTotalCopies() {
    return Object.values(this.copyQuantities).reduce((sum, qty) => sum + qty, 0);
  }

  isItemSelected(itemId) {
    return this.selectedItems.includes(parseInt(itemId));
  }
}

// Initialize the selection manager
let itemSelectionManager;

function initializeItemSelection() {
  if (!itemSelectionManager) {
    itemSelectionManager = new ItemSelectionManager();
  } else {
    itemSelectionManager.updateUI();
  }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initializeItemSelection);
document.addEventListener('turbo:load', initializeItemSelection);
document.addEventListener('turbo:render', initializeItemSelection);

// Export for ES6 modules if needed
export { ItemSelectionManager, initializeItemSelection };

// Make it globally available for non-module usage
if (typeof window !== 'undefined') {
  window.ItemSelectionManager = ItemSelectionManager;
  window.itemSelectionManager = itemSelectionManager;
  window.initializeItemSelection = initializeItemSelection;
}