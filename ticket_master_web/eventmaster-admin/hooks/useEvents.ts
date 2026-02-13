import { useState, useEffect } from 'react';
import { Event, EventStatus } from '../types';

export const useEvents = (isAuthenticated: boolean) => {
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchEvents = async () => {
    if (!isAuthenticated) return;
    
    setLoading(true);
    try {
      const token = localStorage.getItem('authToken');
      const response = await fetch('http://localhost:8000/api/evenements/', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement des événements');
      }

      const data = await response.json();
      
      // Charger les tickets pour chaque événement en parallèle
      const eventsWithTickets = await Promise.all(
        data.results.map(async (event: any) => {
          // Charger les tickets de cet événement
          let ticketTypes = [];
          try {
            const ticketsResponse = await fetch(`http://localhost:8000/api/evenements/${event.id_evenement}/tickets/`, {
              headers: {
                'Authorization': `Bearer ${token}`
              }
            });

            if (ticketsResponse.ok) {
              const ticketsData = await ticketsResponse.json();
              ticketTypes = (ticketsData.tickets || []).map((ticket: any) => ({
                id: ticket.id_ticket?.toString() || '',
                name: ticket.type || '',
                price: ticket.prix || 0,
                quantityTotal: ticket.stock || 0,
                quantitySold: 0
              }));
            }
          } catch (error) {
            console.error(`Erreur lors du chargement des tickets pour l'événement ${event.id_evenement}:`, error);
          }

          return {
            id: event.id_evenement?.toString() || '',
            title: event.titre_evenement || '',
            date: event.date || '',
            startTime: event.heure_debut || '',
            endTime: event.heure_fin || '',
            location: event.lieu || '',
            eventType: event.type_evenement || 'Autre',
            imageUrl: event.image || 'https://via.placeholder.com/800x400',
            status: 'published' as EventStatus,
            ticketsValidated: 0,
            ticketTypes: ticketTypes,
            description: event.description || ''
          };
        })
      );

      setEvents(eventsWithTickets);
    } catch (error) {
      console.error('Erreur lors du chargement des événements:', error);
      setError(error instanceof Error ? error.message : 'Unknown error');
    } finally {
        setLoading(false);
    }
  };

  useEffect(() => {
    fetchEvents();
  }, [isAuthenticated]);

  return { events, setEvents, fetchEvents, loading, error };
};
