export type EventStatus = 'published' | 'draft' | 'ended';

export interface TicketType {
  id: string;
  name: string;
  price: number;
  quantityTotal: number;
  quantitySold: number;
}

export interface Event {
  id: string;
  title: string;
  date: string;
  startTime?: string;
  endTime?: string;
  location: string;
  eventType: string;
  status: EventStatus;
  imageUrl: string;
  description?: string;
  ticketsValidated: number;
  ticketTypes: TicketType[];
}

export interface SalesData {
  date: string;
  revenue: number;
  ticketsSold: number;
}

export enum Tab {
  DASHBOARD = 'dashboard',
  EVENTS = 'events',
  TICKETS = 'tickets',
  STATISTICS = 'statistics',
  USERS = 'users',
  CLIENTS = 'clients',
  ACCOUNTS = 'accounts',
  SETTINGS = 'settings',
  AI_ASSISTANT = 'ai_assistant',
  ANALYTICS = 'analytics' // Keeping for safety, though unused now
}

export interface User {
  id: number;
  name: string;
  email: string;
  role: string;
  status: 'Actif' | 'Inactif' | 'Suspendu';
  avatar: string;
  color: string;
  revenueGenerated?: number;
  referralCount?: number;
  lastLogin?: string;
}

export interface AIPrediction {
  summary: string;
  suggestedAction: string;
  projectedRevenue: number;
  confidenceScore: number;
}

export interface AIMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}
