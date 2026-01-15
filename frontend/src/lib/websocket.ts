// lib/websocket.ts
import { ref } from 'vue'

export class WebSocketManager {
  private socket: WebSocket | null = null
  private reconnectAttempts = 0
  private maxReconnectAttempts = 5
  private reconnectBaseDelay = 1000
  private reconnectTimeout: NodeJS.Timeout | null = null
  
  public status = ref<'disconnected' | 'connecting' | 'connected' | 'reconnecting'>('disconnected')
  public error = ref<string | null>(null)
  
  constructor(
    private url: string,
    private protocols?: string | string[],
    private onMessage?: (data: any) => void,
    private onOpen?: () => void,
    private onClose?: (event: CloseEvent) => void,
    private onError?: (event: Event) => void
  ) {}
  
  connect(): void {
    this.cleanup()
    
    try {
      this.status.value = 'connecting'
      this.socket = new WebSocket(this.url, this.protocols)
      this.setupEventHandlers()
    } catch (err) {
      this.handleError('Failed to create WebSocket')
    }
  }
  
  disconnect(code?: number, reason?: string): void {
    if (this.socket) {
      this.socket.close(code || 1000, reason)
    }
    this.cleanup()
  }
  
  send(data: any): boolean {
    if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
      this.error.value = 'WebSocket not connected'
      return false
    }
    
    try {
      const jsonData = JSON.stringify(data)
      this.socket.send(jsonData)
      return true
    } catch (err) {
      this.handleError('Failed to send message')
      return false
    }
  }
  
  private setupEventHandlers(): void {
    if (!this.socket) return
    
    this.socket.onopen = () => {
      this.status.value = 'connected'
      this.reconnectAttempts = 0
      this.error.value = null
      this.onOpen?.()
    }
    
    this.socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        this.onMessage?.(data)
      } catch (err) {
        console.error('Failed to parse WebSocket message:', err)
      }
    }
    
    this.socket.onclose = (event) => {
      this.status.value = 'disconnected'
      this.onClose?.(event)
      
      if (!event.wasClean) {
        this.attemptReconnect()
      }
    }
    
    this.socket.onerror = (event) => {
      this.handleError('WebSocket error')
      this.onError?.(event)
    }
  }
  
  private attemptReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      this.error.value = 'Max reconnection attempts reached'
      return
    }
    
    const delay = this.reconnectBaseDelay * Math.pow(2, this.reconnectAttempts)
    this.status.value = 'reconnecting'
    
    this.reconnectTimeout = setTimeout(() => {
      this.reconnectAttempts++
      this.connect()
    }, delay)
  }
  
  private handleError(message: string): void {
    this.error.value = message
    this.status.value = 'disconnected'
  }
  
  private cleanup(): void {
    if (this.socket) {
      this.socket.onopen = null
      this.socket.onmessage = null
      this.socket.onclose = null
      this.socket.onerror = null
      this.socket = null
    }
    
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout)
      this.reconnectTimeout = null
    }
  }
  
  isConnected(): boolean {
    return this.socket?.readyState === WebSocket.OPEN
  }
  
  getReadyState(): number {
    return this.socket?.readyState || WebSocket.CLOSED
  }
}
