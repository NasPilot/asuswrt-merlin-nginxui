import '@testing-library/jest-dom'
import { config } from '@vue/test-utils'

// Setup Vue Test Utils config for Vue 3
config.global.plugins = []

// Global test setup
beforeEach(() => {
  // Reset any mocks or test state before each test
  jest.clearAllMocks()
})

// Mock global objects that might not be available in test environment
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(), // deprecated
    removeListener: jest.fn(), // deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
})

// Mock ResizeObserver
class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
}

window.ResizeObserver = ResizeObserver

// Mock IntersectionObserver
class IntersectionObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
}

window.IntersectionObserver = IntersectionObserver

// Configure Vue Test Utils
config.global.mocks = {
  $t: (key: string) => key, // Mock i18n
  $tc: (key: string) => key,
  $te: () => true,
}

// Mock axios for HTTP requests
jest.mock('axios', () => ({
  default: {
    create: jest.fn(() => ({
      get: jest.fn(() => Promise.resolve({ data: {} })),
      post: jest.fn(() => Promise.resolve({ data: {} })),
      put: jest.fn(() => Promise.resolve({ data: {} })),
      delete: jest.fn(() => Promise.resolve({ data: {} })),
      interceptors: {
        request: {
          use: jest.fn(),
          eject: jest.fn(),
        },
        response: {
          use: jest.fn(),
          eject: jest.fn(),
        },
      },
    })),
    get: jest.fn(() => Promise.resolve({ data: {} })),
    post: jest.fn(() => Promise.resolve({ data: {} })),
    put: jest.fn(() => Promise.resolve({ data: {} })),
    delete: jest.fn(() => Promise.resolve({ data: {} })),
  },
}))

// Suppress console warnings in tests
const originalWarn = console.warn
beforeAll(() => {
  console.warn = (...args: any[]) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Vue warn')
    ) {
      return
    }
    originalWarn(...args)
  }
})

afterAll(() => {
  console.warn = originalWarn
})
