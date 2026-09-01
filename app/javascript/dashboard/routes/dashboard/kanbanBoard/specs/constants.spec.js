import { formatMoney, formatDueDate } from '../constants';

// Chatwoot hands these formatters its own locale, which is written pt_BR. The
// Intl APIs want BCP 47 and throw a RangeError on the underscore form, and since
// both run inside computeds that error used to take the whole column off the
// board: a card with a value made "Agendado" disappear.
const CHATWOOT_LOCALE = 'pt_BR';

describe('#formatMoney', () => {
  it('formats a value under the locale Chatwoot actually stores', () => {
    expect(() => formatMoney(30000, CHATWOOT_LOCALE)).not.toThrow();
    expect(formatMoney(30000, CHATWOOT_LOCALE)).toContain('300');
  });

  it('accepts a locale that is already BCP 47', () => {
    expect(formatMoney(30000, 'pt-BR')).toContain('300');
  });

  it('falls back to pt-BR when no locale is given', () => {
    expect(formatMoney(30000)).toContain('300');
  });

  it('renders nothing for a card with no value', () => {
    expect(formatMoney(0, CHATWOOT_LOCALE)).toBeNull();
    expect(formatMoney(null, CHATWOOT_LOCALE)).toBeNull();
  });
});

describe('#formatDueDate', () => {
  const t = key => key;
  const daysFromNow = days => {
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date.toISOString();
  };

  it('formats a far date under the locale Chatwoot actually stores', () => {
    expect(() => formatDueDate(daysFromNow(45), t, CHATWOOT_LOCALE)).not.toThrow();
    expect(formatDueDate(daysFromNow(45), t, CHATWOOT_LOCALE)).toEqual(
      expect.any(String)
    );
  });

  it('says today, tomorrow and yesterday in words', () => {
    expect(formatDueDate(daysFromNow(0), t, CHATWOOT_LOCALE)).toBe(
      'KANBAN.CARD.DUE_TODAY'
    );
    expect(formatDueDate(daysFromNow(1), t, CHATWOOT_LOCALE)).toBe(
      'KANBAN.CARD.DUE_TOMORROW'
    );
    expect(formatDueDate(daysFromNow(-1), t, CHATWOOT_LOCALE)).toBe(
      'KANBAN.CARD.DUE_YESTERDAY'
    );
  });

  it('renders nothing when the card has no due date', () => {
    expect(formatDueDate(null, t, CHATWOOT_LOCALE)).toBeNull();
  });
});
