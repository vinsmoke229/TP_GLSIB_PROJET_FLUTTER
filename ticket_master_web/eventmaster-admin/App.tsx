import React, { useState } from 'react';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import MainLayout from './layouts/MainLayout';
import { Tab } from './types';
import { Dashboard } from './features/dashboard/Dashboard';
import { EventCard } from './features/events/EventCard'; // Used in Dashboard? No, Dashboard iterates itself? No, Dashboard has EventCards? No, Events tab has EventCards.
import { TicketSales } from './features/tickets/TicketSales';
import { Clients } from './features/clients/Clients';
import { Users } from './features/users/Users';
import { Settings } from './features/settings/Settings';
import { AIAssistant } from './features/ai/AIAssistant';
import { Accounts } from './features/accounts/Accounts';
import { Login } from './features/auth/Login';
import { CreateEventModal } from './features/events/CreateEventModal';
import { ManageTicketsModal } from './features/events/ManageTicketsModal';
import AIPanel from './features/ai/AIPanel';
import { Statistics } from './features/dashboard/Statistics';
import { Calendar, Search, Filter, Tag, Plus, Bot } from 'lucide-react';
import { useEvents } from './hooks/useEvents';

// --- MOCK DATA ---
const mockSalesData = [
  { date: '12 Juin', revenue: 1200, ticketsSold: 24 },
  { date: '13 Juin', revenue: 1500, ticketsSold: 30 },
  { date: '14 Juin', revenue: 1100, ticketsSold: 22 },
  { date: '15 Juin', revenue: 2400, ticketsSold: 45 },
  { date: '16 Juin', revenue: 3200, ticketsSold: 60 },
  { date: '17 Juin', revenue: 2800, ticketsSold: 52 },
  { date: '18 Juin', revenue: 3500, ticketsSold: 68 },
];

const AppContent: React.FC = () => {
  const { isAuthenticated, adminInfo, login } = useAuth();
  const [activeTab, setActiveTab] = useState<Tab>(Tab.DASHBOARD);
  
  // Custom Hook for Events
  const { events, fetchEvents } = useEvents(isAuthenticated);

  // Modal States
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isTicketModalOpen, setIsTicketModalOpen] = useState(false);
  const [selectedEventId, setSelectedEventId] = useState<string | null>(null);
  const [editingEvent, setEditingEvent] = useState<any | null>(null);
  const [isAIChatOpen, setIsAIChatOpen] = useState(false);

  // Filters State
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'published' | 'draft' | 'ended'>('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  // Filtered Events Logic
  const filteredEvents = events.filter(event => {
    const matchesSearch = event.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      event.location.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || event.status === statusFilter;
    const matchesType = typeFilter === 'all' || event.eventType === typeFilter;

    const eventDate = new Date(event.date);
    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;
    const matchesDate = (!start || eventDate >= start) && (!end || eventDate <= end);

    return matchesSearch && matchesStatus && matchesType && matchesDate;
  });

  const uniqueEventTypes = Array.from(new Set(events.map(e => e.eventType)));

  const handleEditEvent = (id: string) => {
    setSelectedEventId(id);
    setIsTicketModalOpen(true);
  };

  const handleOpenEditEventModal = (id: string) => {
    const eventToEdit = events.find(e => e.id === id);
    if (eventToEdit) {
      setEditingEvent(eventToEdit);
      setIsCreateModalOpen(true);
    }
  };

  const handleCloseEventModal = () => {
    setIsCreateModalOpen(false);
    setEditingEvent(null);
  };

  const handleUpdateEvent = (updatedEvent: any) => {
    // Optimistic update or refetch
    fetchEvents(); 
  };

  const selectedEvent = events.find(e => e.id === selectedEventId) || null;

  if (!isAuthenticated) {
    return <Login onLogin={login} />;
  }

  return (
    <MainLayout activeTab={activeTab} setActiveTab={setActiveTab}>
      <div className="w-full mx-auto space-y-4 sm:space-y-6">
        {activeTab === Tab.DASHBOARD && (
          <Dashboard
            events={events}
            salesData={mockSalesData}
            onViewReports={() => setActiveTab(Tab.STATISTICS)}
            onCreateEvent={() => setIsCreateModalOpen(true)}
            adminInfo={adminInfo}
          />
        )}

        {activeTab === Tab.EVENTS && (
          <div className="space-y-4 sm:space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-0">
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-500 to-pink-600 flex items-center justify-center">
                    <Calendar className="w-6 h-6 text-white" />
                  </div>
                  Évènements
                </h1>
                <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
                  Gérez et organisez tous vos évènements
                </p>
              </div>
              <button
                onClick={() => setIsCreateModalOpen(true)}
                className="bg-gray-900 hover:bg-black text-white px-5 py-2.5 rounded-xl text-sm font-semibold flex items-center gap-2 transition-all shadow-lg hover:shadow-xl hover:-translate-y-0.5 active:translate-y-0 transform"
              >
                <Plus className="w-4 h-4" />
                <span>Nouveau</span>
              </button>
            </div>

            {/* Filters Bar */}
            <div className="bg-white dark:bg-gray-800 p-3 sm:p-4 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm space-y-3">
              {/* Search Bar - Full Width */}
              <div className="relative w-full">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Rechercher un événement..."
                  className="w-full pl-9 pr-4 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 outline-none transition-all text-gray-900 dark:text-white"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>

              {/* Filters Row */}
              <div className="flex flex-col sm:flex-row gap-2 sm:gap-3">
                {/* Date Range */}
                <div className="flex items-center gap-2 flex-1">
                  <input
                    type="date"
                    className="flex-1 px-3 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-emerald-500 text-gray-600 dark:text-gray-200"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                  <span className="text-gray-400 text-sm">-</span>
                  <input
                    type="date"
                    className="flex-1 px-3 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-emerald-500 text-gray-600 dark:text-gray-200"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                  />
                </div>

                {/* Status Filter */}
                <div className="flex items-center gap-2 px-3 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 flex-shrink-0">
                  <Filter className="w-4 h-4 text-gray-500" />
                  <select
                    className="bg-transparent text-sm text-gray-700 dark:text-gray-200 font-medium outline-none cursor-pointer"
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value as any)}
                  >
                    <option value="all">Tous les statuts</option>
                    <option value="published">Publié</option>
                    <option value="draft">Brouillon</option>
                    <option value="ended">Terminé</option>
                  </select>
                </div>

                {/* Type Filter */}
                <div className="flex items-center gap-2 px-3 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 flex-shrink-0">
                  <Tag className="w-4 h-4 text-gray-500" />
                  <select
                    className="bg-transparent text-sm text-gray-700 dark:text-gray-200 font-medium outline-none cursor-pointer"
                    value={typeFilter}
                    onChange={(e) => setTypeFilter(e.target.value)}
                  >
                    <option value="all">Tous les types</option>
                    {uniqueEventTypes.map(type => (
                      <option key={type} value={type}>{type}</option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
              {filteredEvents.map(event => (
                <EventCard key={event.id} event={event} onEdit={handleEditEvent} onEditEvent={handleOpenEditEventModal} />
              ))}
              {filteredEvents.length === 0 && (
                <div className="col-span-full py-12 text-center text-gray-500 bg-white rounded-xl border border-dashed border-gray-300">
                  Aucun événement ne correspond à votre recherche.
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === Tab.TICKETS && (
          <TicketSales events={events} />
        )}

        {activeTab === Tab.STATISTICS && (
          <Statistics salesData={mockSalesData} events={events} />
        )}

        {activeTab === Tab.CLIENTS && (
          <Clients />
        )}

        {activeTab === Tab.USERS && (
          <Users />
        )}

        {activeTab === Tab.SETTINGS && (
          <Settings />
        )}

        {activeTab === Tab.AI_ASSISTANT && (
          <AIAssistant events={events} salesData={mockSalesData} />
        )}

        {activeTab === Tab.ACCOUNTS && (
          <Accounts />
        )}
      </div>

      {/* Modals */}
      <CreateEventModal
        isOpen={isCreateModalOpen}
        onClose={handleCloseEventModal}
        onSuccess={fetchEvents}
        event={editingEvent}
      />

      <ManageTicketsModal
        isOpen={isTicketModalOpen}
        onClose={() => setIsTicketModalOpen(false)}
        event={selectedEvent}
        onUpdateEvent={handleUpdateEvent}
      />

      <AIPanel
        isOpen={isAIChatOpen}
        onClose={() => setIsAIChatOpen(false)}
        events={events}
        salesData={mockSalesData}
      />

      {/* Floating AI Button */}
      <button
        onClick={() => setActiveTab(Tab.AI_ASSISTANT)}
        className="fixed bottom-24 right-8 w-16 h-16 bg-gradient-to-br from-emerald-500 to-teal-600 text-white rounded-full shadow-2xl hover:shadow-emerald-500/50 transition-all duration-300 flex items-center justify-center z-50 animate-bounce-infinite hover:scale-110"
        title="Assistant IA"
      >
        <Bot className="w-8 h-8" />
      </button>
    </MainLayout>
  );
};

const App: React.FC = () => {
  return (
    <ThemeProvider>
      <AuthProvider>
        <AppContent />
      </AuthProvider>
    </ThemeProvider>
  );
};

export default App;