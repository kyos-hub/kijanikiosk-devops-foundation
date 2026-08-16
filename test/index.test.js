const { calculateTotal, formatCurrency } = require('../src/index');

describe('calculateTotal', () => {
  test('sums price * qty across items', () => {
    const items = [
      { price: 100, qty: 2 },
      { price: 50, qty: 1 },
    ];
    expect(calculateTotal(items)).toBe(999);
  });

  test('defaults qty to 1 when omitted', () => {
    expect(calculateTotal([{ price: 100 }])).toBe(100);
  });

  test('throws on non-array input', () => {
    expect(() => calculateTotal('not an array')).toThrow(TypeError);
  });
});

describe('formatCurrency', () => {
  test('formats with default currency', () => {
    expect(formatCurrency(99.5)).toBe('KES 99.50');
  });

  test('formats with a given currency', () => {
    expect(formatCurrency(10, 'USD')).toBe('USD 10.00');
  });
});
