import React from 'react';
import { Calendar, MapPin, QrCode, Tag, Edit2, Clock } from 'lucide-react';
import { Event } from '../../types';

interface EventCardProps {
  event: Event;
  onEdit: (id: string) => void;
  onEditEvent?: (id: string) => void;
}

export const EventCard: React.FC<EventCardProps> = ({ event, onEdit, onEditEvent }) => {
  const totalSold = event.ticketTypes.reduce((acc, t) => acc + t.quantitySold, 0);
  const totalCapacity = event.ticketTypes.reduce((acc, t) => acc + t.quantityTotal, 0);
  const percentSold = totalCapacity > 0 ? Math.round((totalSold / totalCapacity) * 100) : 0;

  return (
    <div 
      className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden hover:shadow-lg hover:border-emerald-300 dark:hover:border-emerald-700 transition-all group relative cursor-pointer"
      onClick={() => onEditEvent && onEditEvent(event.id)}
    >
      {/* Badge hover pour éditer - Version moderne */}
      <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 z-[5] pointer-events-none"></div>
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10 bg-emerald-600 text-white text-xs font-semibold px-3 py-1.5 rounded-lg opacity-0 group-hover:opacity-100 transition-all duration-300 transform group-hover:scale-105 flex items-center gap-1.5 shadow-lg backdrop-blur-sm">
        Cliquer pour modifier
      </div>
      
      <div className="h-32 bg-gray-200 relative overflow-hidden">
        <img
          src={event.imageUrl}
          alt={event.title}
          className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent opacity-60"></div>
        <div className="absolute top-2 right-2">
          <span className={`px-2 py-1 rounded-full text-xs font-semibold backdrop-blur-md ${event.status === 'published' ? 'bg-green-500/80 text-white' :
              event.status === 'draft' ? 'bg-yellow-500/80 text-white' :
                'bg-gray-500/80 text-white'
            }`}>
            {event.status === 'published' ? 'Publié' : event.status === 'draft' ? 'Brouillon' : 'Terminé'}
          </span>
        </div>
        <div className="absolute bottom-2 left-2">
          <span className="px-2 py-1 rounded-md text-xs font-medium bg-white/90 dark:bg-gray-800/90 text-gray-800 dark:text-gray-200 flex items-center gap-1">
            <Tag className="w-3 h-3" />
            {event.eventType}
          </span>
        </div>
      </div>
      <div className="p-5">
        <h3 className="font-bold text-lg text-gray-900 dark:text-white mb-2 truncate">{event.title}</h3>

        <div className="space-y-2 text-sm text-gray-600 dark:text-gray-400 mb-4">
          <div className="flex items-center">
            <Calendar className="w-4 h-4 mr-2 text-emerald-500" />
            {new Date(event.date).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}
          </div>
          {event.startTime && (
            <div className="flex items-center">
              <Clock className="w-4 h-4 mr-2 text-emerald-500" />
              {event.startTime} {event.endTime ? `- ${event.endTime}` : ''}
            </div>
          )}
          <div className="flex items-center">
            <MapPin className="w-4 h-4 mr-2 text-emerald-500" />
            {event.location}
          </div>
        </div>

        <div className="border-t border-gray-100 dark:border-gray-700 pt-4">
          <div className="flex justify-between text-sm mb-1">
            <span className="text-gray-500 dark:text-gray-400">Ventes</span>
            <span className="font-medium text-gray-900 dark:text-gray-200">{totalSold} / {totalCapacity}</span>
          </div>
          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 mb-4">
            <div
              className="bg-emerald-500 h-2 rounded-full"
              style={{ width: `${percentSold}%` }}
            ></div>
          </div>

          <div className="flex justify-between items-center text-xs text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-700/50 p-2 rounded">
            <div className="flex items-center gap-1">
              <QrCode className="w-3 h-3 text-emerald-600 dark:text-emerald-400" />
              <span>Validés: <strong className="text-gray-900 dark:text-white">{event.ticketsValidated}</strong></span>
            </div>
            <div>
              <span>Restants: <strong className="text-gray-900 dark:text-white">{totalCapacity - totalSold}</strong></span>
            </div>
          </div>

          <button
            onClick={(e) => {
              e.stopPropagation();
              onEdit(event.id);
            }}
            className="w-full mt-4 py-2 text-sm text-emerald-600 dark:text-emerald-400 font-medium border border-emerald-200 dark:border-emerald-800 rounded-lg hover:bg-emerald-50 dark:hover:bg-emerald-900/30 transition-colors"
          >
            Gérer les tickets
          </button>
        </div>
      </div>
    </div>
  );
};
