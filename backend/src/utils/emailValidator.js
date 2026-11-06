require('dotenv').config();

const ALLOWED_DOMAINS = (process.env.ALLOWED_EMAIL_DOMAINS || '')
  .split(',')
  .map((d) => d.trim().toLowerCase())
  .filter(Boolean);

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

const isValidEmailFormat = (email) => EMAIL_REGEX.test(email);

// compares the exact domain, so "x@fakepatancollege.edu.np" is rejected
const isAllowedDomain = (email) => {
  const domain = email.split('@')[1];
  return ALLOWED_DOMAINS.includes(domain);
};

module.exports = { normalizeEmail, isValidEmailFormat, isAllowedDomain, ALLOWED_DOMAINS };