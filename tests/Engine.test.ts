import { Engine } from '@/modules/Engine'
import axios from 'axios'

// Mock axios
jest.mock('axios')
const mockedAxios = axios as jest.Mocked<typeof axios>

describe('Engine', () => {
  let engine: Engine

  beforeEach(() => {
    engine = new Engine()
    jest.clearAllMocks()
  })

  describe('constructor', () => {
    it('should create an instance with default configuration', () => {
      expect(engine).toBeInstanceOf(Engine)
    })
  })

  describe('submitAction', () => {
    it('should submit action successfully', async () => {
      const mockResponse = {
        data: {
          success: true,
          message: 'Action completed successfully'
        }
      }

      mockedAxios.post.mockResolvedValueOnce(mockResponse)

      const result = await engine.submitAction('test_action', { param: 'value' })

      expect(mockedAxios.post).toHaveBeenCalledWith(
        '/start_apply.htm',
        expect.any(FormData),
        expect.objectContaining({
          headers: expect.objectContaining({
            'Content-Type': 'multipart/form-data'
          }),
          timeout: 30000
        })
      )

      expect(result).toEqual(mockResponse.data)
    })

    it('should handle API errors', async () => {
      const mockError = new Error('Network error')
      mockedAxios.post.mockRejectedValueOnce(mockError)

      await expect(engine.submitAction('test_action', {})).rejects.toThrow('Network error')
    })

    it('should parse HTML response when JSON parsing fails', async () => {
      const mockHtmlResponse = {
        data: '<html><body>Success</body></html>'
      }

      mockedAxios.post.mockResolvedValueOnce(mockHtmlResponse)

      const result = await engine.submitAction('test_action', {})

      expect(result).toEqual({
        success: true,
        html: mockHtmlResponse.data
      })
    })
  })

  describe('checkStatus', () => {
    it('should check service status', async () => {
      const mockResponse = {
        data: {
          nginx_status: 'running',
          nginx_version: '1.20.1'
        }
      }

      mockedAxios.post.mockResolvedValueOnce(mockResponse)

      const result = await engine.checkStatus()

      expect(mockedAxios.post).toHaveBeenCalledWith(
        '/start_apply.htm',
        expect.any(FormData),
        expect.any(Object)
      )

      expect(result).toEqual(mockResponse.data)
    })
  })

  describe('getLogs', () => {
    it('should get logs with default parameters', async () => {
      const mockResponse = {
        data: {
          logs: ['log line 1', 'log line 2'],
          total_lines: 2
        }
      }

      mockedAxios.post.mockResolvedValueOnce(mockResponse)

      const result = await engine.getLogs()

      expect(result).toEqual(mockResponse.data)
    })

    it('should get logs with custom parameters', async () => {
      const mockResponse = {
        data: {
          logs: ['error log 1'],
          total_lines: 1
        }
      }

      mockedAxios.post.mockResolvedValueOnce(mockResponse)

      const result = await engine.getLogs('error', 50)

      expect(result).toEqual(mockResponse.data)
    })
  })

  describe('applyConfig', () => {
    it('should apply configuration', async () => {
      const mockConfig = {
        nginx_enabled: true,
        listen_port: 80,
        server_name: 'localhost'
      }

      const mockResponse = {
        data: {
          success: true,
          message: 'Configuration applied successfully'
        }
      }

      mockedAxios.post.mockResolvedValueOnce(mockResponse)

      const result = await engine.applyConfig(mockConfig)

      expect(result).toEqual(mockResponse.data)
    })
  })

  describe('error handling', () => {
    it('should handle timeout errors', async () => {
      const timeoutError = {
        code: 'ECONNABORTED',
        message: 'timeout of 30000ms exceeded'
      }

      mockedAxios.post.mockRejectedValueOnce(timeoutError)

      await expect(engine.submitAction('test_action', {})).rejects.toMatchObject(timeoutError)
    })

    it('should handle network errors', async () => {
      const networkError = {
        code: 'ENOTFOUND',
        message: 'getaddrinfo ENOTFOUND'
      }

      mockedAxios.post.mockRejectedValueOnce(networkError)

      await expect(engine.submitAction('test_action', {})).rejects.toMatchObject(networkError)
    })
  })
})