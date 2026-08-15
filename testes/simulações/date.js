// testes/simulações/date.js
const FIXED_TIMESTAMP = new Date('2026-08-15T12:00:00Z').getTime();

const OriginalDate = Date;

class MockDate extends OriginalDate {
  constructor(...args) {
    if (args.length === 0) {
      super(FIXED_TIMESTAMP);
    } else {
      super(...args);
    }
  }

  static now() {
    return FIXED_TIMESTAMP;
  }
}

// Ensure instanceof works
MockDate.prototype = OriginalDate.prototype;

window.Date = MockDate;
