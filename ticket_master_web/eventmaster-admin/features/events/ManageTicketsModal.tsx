import React, { useState, useMemo, useEffect } from 'react';
import { X, Plus, Trash2, Ticket, Euro, Hash, Tag, PieChart, TrendingUp, AlertCircle, Sparkles, Edit2 } from 'lucide-react';
import { Event, TicketType } from '../../types';

interface ManageTicketsModalProps {
  isOpen: boolean;
  onClose: () => void;
  event: Event | null;
  onUpdateEvent: (updatedEvent: Event) => void;
}

export const ManageTicketsModal: React.FC<ManageTicketsModalProps> = ({ isOpen, onClose, event, onUpdateEvent }) => {
  const [newTicket, setNewTicket] = useState({
    name: '',
    price: '',
    quantity: ''
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [tickets, setTickets] = useState<TicketType[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [editingTicket, setEditingTicket] = useState<TicketType | null>(null);

  const stats = useMemo(() => {
    return tickets.reduce((acc, t) => ({
      capacity: acc.capacity + t.quantityTotal,
      revenue: acc.revenue + (t.price * t.quantityTotal),
      count: acc.count + 1
    }), { capacity: 0, revenue: 0, count: 0 });
  }, [tickets]);

  // Charger les tickets depuis l'API
  const fetchTickets = async () => {
    if (!event) return;
    
    setIsLoading(true);
    try {
      const token = localStorage.getItem('authToken');
      const response = await fetch(`http://localhost:8000/api/evenements/${event.id}/tickets/`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement des tickets');
      }

      const data = await response.json();
      console.log('Tickets data:', data);
      
      // Map API fields to frontend fields
      const mappedTickets = (data.tickets || []).map((ticket: any) => ({
        id: ticket.id_ticket?.toString() || '',
        name: ticket.type || '',
        price: ticket.prix || 0,
        quantityTotal: ticket.stock || 0,
        quantitySold: 0
      }));

      setTickets(mappedTickets);
      
      // Mettre à jour l'événement parent avec les tickets chargés
      onUpdateEvent({
        ...event,
        ticketTypes: mappedTickets
      });
    } catch (error) {
      console.error('Erreur lors du chargement des tickets:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (isOpen && event) {
      fetchTickets();
    } else {
      // Réinitialiser le formulaire quand le modal se ferme
      setEditingTicket(null);
      setNewTicket({ name: '', price: '', quantity: '' });
    }
  }, [isOpen, event?.id]);

  if (!isOpen || !event) return null;

  const handleEditTicket = (ticket: TicketType) => {
    setEditingTicket(ticket);
    setNewTicket({
      name: ticket.name,
      price: ticket.price.toString(),
      quantity: ticket.quantityTotal.toString()
    });
  };

  const handleCancelEdit = () => {
    setEditingTicket(null);
    setNewTicket({ name: '', price: '', quantity: '' });
  };

  const handleAddTicket = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTicket.name || !newTicket.price || !newTicket.quantity) return;

    setIsSubmitting(true);

    try {
      const token = localStorage.getItem('authToken');
      
      // Map frontend fields to backend fields
      const ticketData = {
        type: newTicket.name,
        prix: parseFloat(newTicket.price),
        stock: parseInt(newTicket.quantity),
        id_evenement: parseInt(event.id)
      };

      let response;
      if (editingTicket) {
        // Mode édition : PUT
        response = await fetch(`http://localhost:8000/api/tickets/${editingTicket.id}/`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify(ticketData)
        });
      } else {
        // Mode création : POST
        response = await fetch('http://localhost:8000/api/tickets/', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify(ticketData)
        });
      }

      if (!response.ok) {
        throw new Error(editingTicket ? 'Erreur lors de la modification du ticket' : 'Erreur lors de la création du ticket');
      }

      // Recharger les tickets depuis l'API
      await fetchTickets();
      setNewTicket({ name: '', price: '', quantity: '' });
      setEditingTicket(null);
    } catch (error) {
      console.error('Erreur:', error);
      alert(editingTicket ? 'Erreur lors de la modification du ticket' : 'Erreur lors de la création du ticket');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRemoveTicket = async (ticketId: string) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer ce ticket ?')) return;

    try {
      const token = localStorage.getItem('authToken');
      const response = await fetch(`http://localhost:8000/api/tickets/${ticketId}/`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors de la suppression du ticket');
      }

      // Recharger les tickets depuis l'API
      await fetchTickets();
    } catch (error) {
      console.error('Erreur:', error);
      alert('Erreur lors de la suppression du ticket');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-gray-900/60 backdrop-blur-sm transition-opacity" 
        onClick={onClose}
      ></div>
      
      {/* Modal Container */}
      <div className="bg-gray-50 dark:bg-gray-900 w-full h-full md:h-auto md:max-h-[85vh] md:rounded-2xl shadow-2xl md:max-w-5xl overflow-hidden relative z-10 flex flex-col md:flex-row animate-in fade-in zoom-in-95 duration-200">
         
         {/* Left Side: Ticket List & Stats */}
         <div className="flex-1 flex flex-col h-full overflow-hidden relative">
             <div className="p-6 border-b border-gray-200 bg-white flex justify-between items-center shrink-0">
                <div>
                  <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                    <Ticket className="w-5 h-5 text-emerald-500" />
                    Configuration Billetterie
                  </h2>
                  <p className="text-sm text-gray-500 mt-1 max-w-md truncate">{event.title}</p>
                </div>
                <button onClick={onClose} className="md:hidden text-gray-400 hover:text-gray-600">
                  <X className="w-6 h-6" />
                </button>
             </div>
             
             {/* Stats Row */}
             <div className="grid grid-cols-3 gap-4 px-6 py-6 bg-gray-50 shrink-0 border-b border-gray-100">
                <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
                   <div className="flex items-center gap-2 text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">
                      <Hash className="w-3 h-3" /> Types
                   </div>
                   <div className="text-2xl font-bold text-gray-900">{stats.count}</div>
                </div>
                <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
                   <div className="flex items-center gap-2 text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">
                      <PieChart className="w-3 h-3" /> Capacité
                   </div>
                   <div className="text-2xl font-bold text-gray-900">{stats.capacity}</div>
                </div>
                <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 relative overflow-hidden group">
                   <div className="relative z-10">
                      <div className="flex items-center gap-2 text-xs font-semibold text-emerald-600 uppercase tracking-wider mb-1">
                          <TrendingUp className="w-3 h-3" /> Potentiel
                      </div>
                      <div className="text-2xl font-bold text-emerald-700">{stats.revenue.toLocaleString()} FCFA</div>
                   </div>
                   <div className="absolute right-0 bottom-0 opacity-10 transform translate-x-2 translate-y-2 group-hover:scale-110 transition-transform">
                      <Euro className="w-16 h-16 text-emerald-500" />
                   </div>
                </div>
             </div>

             {/* Scrollable List */}
             <div className="flex-1 overflow-y-auto p-6 space-y-3">
                {isLoading ? (
                  <div className="h-full flex items-center justify-center">
                    <div className="text-center">
                      <div className="w-12 h-12 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto mb-4"></div>
                      <p className="text-gray-500">Chargement des tickets...</p>
                    </div>
                  </div>
                ) : tickets.length === 0 ? (
                  <div className="h-full flex flex-col items-center justify-center text-center p-8 border-2 border-dashed border-gray-200 rounded-xl bg-white/50">
                    <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4 text-gray-400">
                      <Tag className="w-8 h-8" />
                    </div>
                    <h3 className="text-lg font-medium text-gray-900">Aucun ticket configuré</h3>
                    <p className="text-gray-500 max-w-xs mt-2">Utilisez le panneau de droite pour créer votre première catégorie de billets.</p>
                  </div>
                ) : (
                  tickets.map((ticket) => {
                    const percentSold = ticket.quantityTotal > 0 ? (ticket.quantitySold / ticket.quantityTotal) * 100 : 0;
                    return (
                      <div 
                        key={ticket.id} 
                        className={`bg-white border rounded-xl p-4 shadow-sm hover:shadow-md transition-all group relative overflow-hidden cursor-pointer ${
                          editingTicket?.id === ticket.id ? 'border-emerald-500 ring-2 ring-emerald-200' : 'border-gray-100'
                        }`}
                        onClick={() => handleEditTicket(ticket)}
                      >
                        {/* Badge d'édition - Version moderne */}
                        {editingTicket?.id === ticket.id ? (
                          <div className="absolute top-3 right-3 z-20 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white text-xs font-bold px-3 py-1.5 rounded-lg flex items-center gap-1.5 shadow-lg animate-pulse">
                            <Edit2 className="w-3.5 h-3.5" />
                            En édition
                          </div>
                        ) : null}
                        
                        <div className="flex justify-between items-start relative z-10">
                          <div className="flex items-start gap-4">
                             <div className="w-12 h-12 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0 border border-emerald-100">
                                <span className="font-bold text-lg">{ticket.price} FCFA</span>
                             </div>
                             <div>
                                <h4 className="font-bold text-gray-900 text-lg leading-tight">{ticket.name}</h4>
                                <div className="text-sm text-gray-500 mt-1 flex items-center gap-2">
                                  <span className="font-medium text-gray-700">{ticket.quantitySold}</span>
                                  <span>vendus sur</span>
                                  <span className="font-medium text-gray-700">{ticket.quantityTotal}</span>
                                </div>
                             </div>
                          </div>
                          <button 
                            onClick={(e) => {
                              e.stopPropagation();
                              handleRemoveTicket(ticket.id);
                            }}
                            disabled={ticket.quantitySold > 0}
                            className={`p-2 rounded-lg transition-colors ${
                              ticket.quantitySold > 0 
                                ? 'text-gray-200 cursor-not-allowed' 
                                : 'text-gray-400 hover:bg-red-50 hover:text-red-500'
                            }`}
                          >
                            <Trash2 className="w-5 h-5" />
                          </button>
                        </div>
                        
                        {/* Progress Bar */}
                        <div className="mt-4 pt-4 border-t border-gray-50">
                          <div className="flex justify-between text-xs mb-1.5">
                            <span className="font-medium text-gray-500">Progression des ventes</span>
                            <span className="font-bold text-emerald-600">{Math.round(percentSold)}%</span>
                          </div>
                          <div className="w-full bg-gray-100 rounded-full h-2 overflow-hidden">
                            <div 
                              className="bg-emerald-500 h-full rounded-full transition-all duration-500" 
                              style={{ width: `${percentSold}%` }}
                            ></div>
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
             </div>
         </div>

         {/* Right Side: Add Form (Sticky on Desktop) */}
         <div className="w-full md:w-[350px] bg-white border-l border-gray-200 flex flex-col shrink-0 h-full">
            <div className="p-6 bg-gray-50 border-b border-gray-200 flex justify-between items-center">
                <h3 className="text-gray-900 font-bold flex items-center gap-2">
                    <Plus className="w-5 h-5 text-emerald-600"/> 
                    {editingTicket ? 'Modifier la Catégorie' : 'Nouvelle Catégorie'}
                </h3>
                <button onClick={onClose} className="hidden md:block text-gray-400 hover:text-gray-600 transition-colors">
                  <X className="w-6 h-6" />
                </button>
            </div>
            
            <div className="p-6 flex-1 overflow-y-auto">
               <form onSubmit={handleAddTicket} className="space-y-5">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-1.5">Nom de la catégorie</label>
                    <div className="relative group">
                      <Tag className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                      <input
                        type="text"
                        required
                        placeholder="Ex: Carré Or, VIP..."
                        className="w-full pl-9 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 font-medium"
                        value={newTicket.name}
                        onChange={(e) => setNewTicket({...newTicket, name: e.target.value})}
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-1.5">Prix du billet</label>
                    <div className="relative group">
                        <Euro className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                        <input
                        type="number"
                        required
                        min="0"
                        step="0.01"
                        placeholder="0.00"
                        className="w-full pl-9 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 font-medium"
                        value={newTicket.price}
                        onChange={(e) => setNewTicket({...newTicket, price: e.target.value})}
                        />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-1.5">Quantité mise en vente</label>
                    <div className="relative group">
                      <Hash className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                      <input
                        type="number"
                        required
                        min="1"
                        placeholder="Ex: 500"
                        className="w-full pl-9 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 font-medium"
                        value={newTicket.quantity}
                        onChange={(e) => setNewTicket({...newTicket, quantity: e.target.value})}
                      />
                    </div>
                  </div>

                  <div className="pt-4 space-y-3">
                    <button
                      type="submit"
                      disabled={isSubmitting}
                      className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl shadow-lg shadow-emerald-200 flex items-center justify-center gap-2 transition-all transform hover:-translate-y-0.5 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-emerald-600 disabled:transform-none"
                    >
                      <Plus className="w-5 h-5" />
                      {isSubmitting 
                        ? (editingTicket ? 'Modification...' : 'Ajout en cours...') 
                        : (editingTicket ? 'Modifier le ticket' : 'Ajouter le ticket')
                      }
                    </button>
                    {editingTicket && (
                      <button
                        type="button"
                        onClick={handleCancelEdit}
                        disabled={isSubmitting}
                        className="w-full py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold rounded-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        Annuler
                      </button>
                    )}
                    <p className="text-xs text-center text-gray-400 mt-4">
                       Ce ticket sera immédiatement disponible à la vente une fois l'événement publié.
                    </p>
                  </div>
               </form>

               {/* AI Tip Box */}
               <div className="mt-8 bg-blue-50 border border-blue-100 rounded-xl p-4 flex gap-3">
                  <Sparkles className="w-5 h-5 text-blue-500 shrink-0 mt-0.5" />
                  <div>
                     <h4 className="text-xs font-bold text-blue-700 uppercase mb-1">Conseil Pro</h4>
                     <p className="text-xs text-blue-600 leading-relaxed">
                        Varier les prix (Early Bird, Regular, VIP) peut augmenter vos revenus de 15% en moyenne.
                     </p>
                  </div>
               </div>
            </div>
         </div>
      </div>
    </div>
  );
};
