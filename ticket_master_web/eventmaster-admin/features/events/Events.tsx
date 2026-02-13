import React, { useState, useMemo } from 'react';
import { Calendar, Plus, Search, Filter, SlidersHorizontal, MapPin, Grid, List } from 'lucide-react';
import { Event } from '../../types';
import { EventCard } from './EventCard';
import { CreateEventModal } from './CreateEventModal';
import { ManageTicketsModal } from './ManageTicketsModal';

interface EventsProps {
  events: Event[];
  onUpdateEvent: (event: Event) => void;
}

const Events: React.FC<EventsProps> = ({ events, onUpdateEvent }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isTicketModalOpen, setIsTicketModalOpen] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [isEditMode, setIsEditMode] = useState(false);

  // Filter events
  const filteredEvents = useMemo(() => {
    return events.filter(event => {
      const matchesSearch = event.title.toLowerCase().includes(searchTerm.toLowerCase()) || 
                            event.location.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesType = filterType === 'all' || event.eventType === filterType;
      
      return matchesSearch && matchesType;
    });
  }, [events, searchTerm, filterType]);

  const handleCreateEvent = () => {
    setSelectedEvent(null);
    setIsEditMode(false);
    setIsCreateModalOpen(true);
  };

  const handleEditEvent = (id: string) => {
    const event = events.find(e => e.id === id);
    if (event) {
      setSelectedEvent(event);
      setIsEditMode(true);
      setIsCreateModalOpen(true);
    }
  };

  const handleManageTickets = (id: string) => {
    const event = events.find(e => e.id === id);
    if (event) {
      setSelectedEvent(event);
      setIsTicketModalOpen(true);
    }
  };

  const handleModalSubmit = () => {
    // Refresh logic if needed, but App.tsx likely handles the data refresh via props update
    // For now just close modal
    setIsCreateModalOpen(false);
  };

  return (
    <div className="space-y-6 animation-fade-in pb-10">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
              <Calendar className="w-6 h-6 text-white" />
            </div>
            Événements
          </h1>
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
            Gérez vos événements, billets et sessions
          </p>
        </div>
        <button
          onClick={handleCreateEvent}
          className="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2.5 rounded-xl text-sm font-semibold flex items-center gap-2 transition-colors shadow-lg shadow-emerald-600/20 active:scale-95"
        >
          <Plus className="w-4 h-4" />
          Créer un événement
        </button>
      </div>

      <CreateEventModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        onSuccess={handleModalSubmit}
        event={selectedEvent}
      />

      {selectedEvent && (
        <ManageTicketsModal
          isOpen={isTicketModalOpen}
          onClose={() => setIsTicketModalOpen(false)}
          event={selectedEvent}
          onUpdateEvent={onUpdateEvent}
        />
      )}

      {/* Toolbar */}
      <div className="bg-white dark:bg-gray-800 p-4 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 space-y-4 md:space-y-0 md:flex md:items-center md:justify-between gap-4">
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Rechercher un événement..."
            className="w-full pl-9 pr-4 py-2.5 bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-emerald-500 outline-none transition-all dark:text-white"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3 overflow-x-auto pb-2 md:pb-0">
          <div className="flex items-center gap-2 px-3 py-2 bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg">
            <Filter className="w-4 h-4 text-gray-500 dark:text-gray-400" />
            <select
              className="bg-transparent text-sm text-gray-700 dark:text-gray-200 font-medium outline-none cursor-pointer"
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
            >
              <option value="all">Tous les types</option>
              <option value="Concert">Concert</option>
              <option value="Conférence">Conférence</option>
              <option value="Festival">Festival</option>
              <option value="Sport">Sport</option>
            </select>
          </div>

          <div className="flex bg-gray-100 dark:bg-gray-700 p-1 rounded-lg">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-1.5 rounded-md transition-all ${viewMode === 'grid' ? 'bg-white dark:bg-gray-600 shadow-sm text-emerald-600 dark:text-emerald-400' : 'text-gray-400 hover:text-gray-600 dark:hover:text-gray-300'}`}
            >
              <Grid className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-1.5 rounded-md transition-all ${viewMode === 'list' ? 'bg-white dark:bg-gray-600 shadow-sm text-emerald-600 dark:text-emerald-400' : 'text-gray-400 hover:text-gray-600 dark:hover:text-gray-300'}`}
            >
              <List className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Events Grid/List */}
      {filteredEvents.length === 0 ? (
        <div className="text-center py-16 bg-white dark:bg-gray-800 rounded-xl border border-dashed border-gray-200 dark:border-gray-700">
          <div className="w-16 h-16 bg-gray-50 dark:bg-gray-700/50 rounded-full flex items-center justify-center mx-auto mb-4">
            <Search className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">Aucun événement trouvé</h3>
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-1 max-w-xs mx-auto">
            Aucun événement ne correspond à vos critères de recherche.
          </p>
          <button 
            onClick={() => { setSearchTerm(''); setFilterType('all'); }}
            className="mt-4 text-emerald-600 font-medium text-sm hover:underline"
          >
            Réinitialiser les filtres
          </button>
        </div>
      ) : (
        <div className={`grid gap-6 ${viewMode === 'grid' ? 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3' : 'grid-cols-1'}`}>
          {filteredEvents.map(event => (
            <EventCard
              key={event.id}
              event={event}
              onEdit={handleManageTickets}
              onEditEvent={handleEditEvent}
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default Events;
