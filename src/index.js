/**
 * KijaniKiosk Payments service — minimal placeholder application.
 * Represents the artifact this week's CI pipeline builds, tests,
 * and publishes to Nexus as a versioned npm package.
 */

function calculateTotal(items) {
  if (!Array.isArray(items)) {
    throw new TypeError('items must be an array');
  }
  return items.reduce((sum, item) => sum + (item.price || 0) * (item.qty || 1), 0);
}

function formatCurrency(amount, currency = 'KES') {
  return `${currency} ${amount.toFixed(2)}`;
}

module.exports = { calculateTotal, formatCurrency };
