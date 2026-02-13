import React, { useMemo, useState } from 'react';
import { Ticket, DollarSign, TrendingUp, Calendar, Search, Filter, ArrowUpRight } from 'lucide-react';
import { Event } from '../../types';

interface TicketSalesProps {
  events: Event[];
}

export const TicketSales: React.FC<TicketSalesProps> = ({ events }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'sold_out' | 'available'>('all');

  // Filter events based on search and date
  const filteredEvents = useMemo(() => {
    return events.filter(event => {
      const matchesSearch = event.title.toLowerCase().includes(searchTerm.toLowerCase());

      const eventDate = new Date(event.date);
      const start = startDate ? new Date(startDate) : null;
      const end = endDate ? new Date(endDate) : null;

      const matchesDate = (!start || eventDate >= start) && (!end || eventDate <= end);

      // Status Filter Logic
      const eventSold = event.ticketTypes.reduce((acc, t) => acc + t.quantitySold, 0);
      const eventCapacity = event.ticketTypes.reduce((acc, t) => acc + t.quantityTotal, 0);
      const percent = eventCapacity > 0 ? (eventSold / eventCapacity) * 100 : 0;
      const isSoldOut = percent === 100;

      const matchesStatus =
        filterStatus === 'all' ? true :
          filterStatus === 'sold_out' ? isSoldOut :
            !isSoldOut;

      return matchesSearch && matchesDate && matchesStatus;
    });
  }, [events, searchTerm, startDate, endDate, filterStatus]);

  // Calculate global stats from FILTERED events
  const globalStats = useMemo(() => {
    let totalSold = 0;
    let totalRevenue = 0;
    let totalCapacity = 0;

    filteredEvents.forEach(e => {
      e.ticketTypes.forEach(t => {
        totalSold += t.quantitySold;
        totalRevenue += t.quantitySold * t.price;
        totalCapacity += t.quantityTotal;
      });
    });

    const sellThroughRate = totalCapacity > 0 ? Math.round((totalSold / totalCapacity) * 100) : 0;

    return { totalSold, totalRevenue, sellThroughRate };
  }, [filteredEvents]);

  return (
    <div className="space-y-4 animation-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
              <Ticket className="w-6 h-6 text-white" />
            </div>
            Billetterie
          </h1>
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
            Suivez les ventes et la disponibilité des billets
          </p>
        </div>
      </div>

      {/* Global Stats Header - Compact Premium Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Total Sold */}
        <div className="relative overflow-hidden bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl p-4 text-white shadow-md shadow-blue-100 transition-transform hover:-translate-y-1 duration-300">
          <div className="absolute top-0 right-0 p-3 opacity-10"><Ticket className="w-16 h-16" /></div>
          <div className="relative z-10 flex flex-col h-full justify-between">
            <div>
              <p className="text-blue-50 font-medium text-xs uppercase tracking-wider">Billets Vendus</p>
              <h3 className="text-2xl font-bold mt-1">{globalStats.totalSold.toLocaleString()}</h3>
            </div>
            <div className="mt-2 flex items-center gap-1 text-blue-100 text-xs bg-white/10 w-fit px-1.5 py-0.5 rounded backdrop-blur-sm">
              <ArrowUpRight className="w-3 h-3" />
              <span>Global volume</span>
            </div>
          </div>
        </div>

        {/* Total Revenue */}
        <div className="relative overflow-hidden bg-gradient-to-br from-emerald-500 to-teal-600 rounded-xl p-4 text-white shadow-md shadow-emerald-100 transition-transform hover:-translate-y-1 duration-300">
          <div className="absolute top-0 right-0 p-3 opacity-10"><DollarSign className="w-16 h-16" /></div>
          <div className="relative z-10 flex flex-col h-full justify-between">
            <div>
              <p className="text-emerald-50 font-medium text-xs uppercase tracking-wider">Chiffre d'Affaires</p>
              <h3 className="text-2xl font-bold mt-1">{globalStats.totalRevenue.toLocaleString()} FCFA</h3>
            </div>
            <div className="mt-2 flex items-center gap-1 text-emerald-100 text-xs bg-white/10 w-fit px-1.5 py-0.5 rounded backdrop-blur-sm">
              <ArrowUpRight className="w-3 h-3" />
              <span>Revenus nets</span>
            </div>
          </div>
        </div>

        {/* Sell Through Rate */}
        <div className="relative overflow-hidden bg-gradient-to-br from-purple-500 to-fuchsia-600 rounded-xl p-4 text-white shadow-md shadow-purple-100 transition-transform hover:-translate-y-1 duration-300">
          <div className="absolute top-0 right-0 p-3 opacity-10"><TrendingUp className="w-16 h-16" /></div>
          <div className="relative z-10 flex flex-col h-full justify-between">
            <div>
              <p className="text-purple-50 font-medium text-xs uppercase tracking-wider">Taux de Remplissage</p>
              <div className="flex items-baseline gap-2 mt-1">
                <h3 className="text-2xl font-bold">{globalStats.sellThroughRate}%</h3>
              </div>
            </div>
            <div className="w-full bg-black/20 rounded-full h-1.5 mt-3">
              <div className="bg-white h-1.5 rounded-full" style={{ width: `${globalStats.sellThroughRate}%` }}></div>
            </div>
          </div>
        </div>
      </div>

      {/* Filters Bar */}
      <div className="bg-white dark:bg-gray-800 p-3 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm flex flex-col md:flex-row gap-4 justify-between items-center">
        <h2 className="text-sm font-bold text-gray-900 dark:text-white whitespace-nowrap hidden md:block uppercase tracking-wide">Détail des ventes</h2>

        <div className="flex flex-col md:flex-row gap-2 w-full justify-end">
          {/* Search */}
          <div className="relative w-full md:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400" />
            <input
              type="text"
              placeholder="Rechercher..."
              className="w-full pl-8 pr-3 py-1.5 text-xs bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 outline-none transition-all text-gray-700 dark:text-gray-200 placeholder-gray-400"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          {/* Date Range Filter */}
          <div className="flex items-center gap-2">
            <div className="relative">
              <input
                type="date"
                className="pl-2 pr-1 py-1.5 text-xs bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg outline-none focus:ring-2 focus:ring-emerald-500 text-gray-600 dark:text-gray-300"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
            </div>
            <span className="text-gray-400">-</span>
            <div className="relative">
              <input
                type="date"
                className="pl-2 pr-1 py-1.5 text-xs bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg outline-none focus:ring-2 focus:ring-emerald-500 text-gray-600 dark:text-gray-300"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
              />
            </div>
          </div>

          {/* Status Filter */}
          <select
            className="px-2 py-1.5 bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg text-xs text-gray-700 dark:text-gray-200 font-medium outline-none focus:ring-2 focus:ring-emerald-500 cursor-pointer"
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value as 'all' | 'sold_out' | 'available')}
          >
            <option value="all">Tous les statuts</option>
            <option value="available">Disponibles</option>
            <option value="sold_out">Complets</option>
          </select>

          <select className="px-2 py-1.5 bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg text-xs text-gray-700 dark:text-gray-200 font-medium outline-none focus:ring-2 focus:ring-emerald-500 cursor-pointer">
            <option>Trier par défaut</option>
            <option>Revenus (Desc)</option>
            <option>Volume (Desc)</option>
          </select>
        </div>
      </div>

      {/* Event List */}
      <div className="space-y-4">
        {filteredEvents.map(event => {
          const eventRevenue = event.ticketTypes.reduce((acc, t) => acc + (t.price * t.quantitySold), 0);
          const eventSold = event.ticketTypes.reduce((acc, t) => acc + t.quantitySold, 0);
          const eventCapacity = event.ticketTypes.reduce((acc, t) => acc + t.quantityTotal, 0);
          const percent = eventCapacity > 0 ? (eventSold / eventCapacity) * 100 : 0;
          const isSoldOut = percent === 100;

          return (
            <div key={event.id} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden group hover:shadow-md transition-shadow">
              <div className="p-4 border-b border-gray-50 dark:border-gray-700 flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gray-50/30 dark:bg-gray-700/30">
                <div className="flex items-center gap-3">
                  <div className="relative">
                    <img src={event.imageUrl} alt="" className="w-12 h-12 rounded-lg object-cover shadow-sm hidden sm:block ring-1 ring-gray-100" />
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900 dark:text-white text-sm flex items-center gap-2">
                      {event.title}
                      {isSoldOut && (
                        <span className="bg-red-100 text-red-600 border border-red-200 text-[10px] font-bold px-2 py-0.5 rounded-full tracking-wide">
                          COMPLET
                        </span>
                      )}
                    </h3>
                    <div className="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                      <span className="flex items-center gap-1"><Calendar className="w-3 h-3" /> {new Date(event.date).toLocaleDateString()}</span>
                      <span>•</span>
                      <span className="bg-emerald-100 dark:bg-emerald-900/40 text-emerald-700 dark:text-emerald-300 px-1.5 py-0 rounded text-[10px] font-medium uppercase">{event.eventType}</span>
                    </div>
                  </div>
                </div>
                <div className="text-right flex items-center gap-4">
                  <div>
                    <p className="text-[10px] text-gray-400 uppercase tracking-wide font-medium">Remplissage</p>
                    <div className="flex items-center justify-end gap-1.5">
                      <div className="w-20 bg-gray-200 rounded-full h-2">
                        <div className={`h-2 rounded-full ${isSoldOut ? 'bg-emerald-500' : 'bg-blue-500'}`} style={{ width: `${percent}%` }}></div>
                      </div>
                      <span className={`text-sm font-bold ${isSoldOut ? 'text-emerald-600' : 'text-gray-700'}`}>{Math.round(percent)}%</span>
                    </div>
                  </div>
                  <div className="pl-4 border-l border-gray-200 dark:border-gray-600">
                    <p className="text-[10px] text-gray-400 uppercase tracking-wide font-medium">Revenu</p>
                    <p className="text-base font-bold text-gray-900 dark:text-white">{eventRevenue.toLocaleString()} FCFA</p>
                  </div>
                </div>
              </div>

              <div className="p-0 overflow-x-auto">
                <table className="w-full text-left border-collapse min-w-[600px]">
                  <thead className="bg-gray-50/50 dark:bg-gray-700/50 text-[10px] uppercase text-gray-400 font-medium tracking-wider">
                    <tr>
                      <th className="px-4 py-2 font-medium">Catégorie</th>
                      <th className="px-4 py-2 font-medium">Prix</th>
                      <th className="px-4 py-2 font-medium">Ventes</th>
                      <th className="px-4 py-2 font-medium w-1/3">Progression</th>
                      <th className="px-4 py-2 text-right font-medium">Total</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50 dark:divide-gray-700 text-xs">
                    {event.ticketTypes.length === 0 ? (
                      <tr>
                        <td colSpan={5} className="px-4 py-6 text-center text-gray-400 italic">Aucun type de ticket configuré</td>
                      </tr>
                    ) : (
                      event.ticketTypes.map(ticket => {
                        const ticketPercent = ticket.quantityTotal > 0 ? (ticket.quantitySold / ticket.quantityTotal) * 100 : 0;
                        const isTicketSoldOut = ticketPercent === 100;
                        return (
                          <tr key={ticket.id} className={`hover:bg-gray-50/30 dark:hover:bg-gray-700/30 transition-colors ${isTicketSoldOut ? 'bg-emerald-50/30 dark:bg-emerald-900/10' : ''}`}>
                            <td className="px-4 py-2.5 font-medium text-gray-900 dark:text-gray-200 flex items-center gap-2">
                              {ticket.name}
                            </td>
                            <td className="px-4 py-2.5 text-gray-500 dark:text-gray-400">{ticket.price} FCFA</td>
                            <td className="px-4 py-2.5">
                              <span className={`font-semibold ${isTicketSoldOut ? 'text-emerald-700 dark:text-emerald-400' : 'text-gray-900 dark:text-gray-200'}`}>{ticket.quantitySold}</span>
                              <span className="text-gray-400"> / {ticket.quantityTotal}</span>
                            </td>
                            <td className="px-4 py-2.5">
                              <div className="flex items-center gap-3">
                                <div className="flex-1 bg-gray-100 rounded-full h-1.5 overflow-hidden">
                                  <div
                                    className={`h-full rounded-full ${ticketPercent >= 100 ? 'bg-emerald-500' : ticketPercent >= 90 ? 'bg-amber-500' : 'bg-blue-400'}`}
                                    style={{ width: `${ticketPercent}%` }}
                                  ></div>
                                </div>
                                <span className={`text-[10px] font-bold w-8 text-right ${isTicketSoldOut ? 'text-emerald-600' : 'text-gray-500'}`}>{Math.round(ticketPercent)}%</span>
                              </div>
                            </td>
                            <td className="px-4 py-2.5 text-right font-medium text-gray-900 dark:text-gray-200">
                              {(ticket.quantitySold * ticket.price).toLocaleString()} FCFA
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          );
        })}

        {filteredEvents.length === 0 && (
          <div className="text-center py-10 bg-white dark:bg-gray-800 rounded-xl border border-dashed border-gray-300 dark:border-gray-700">
            <Filter className="w-10 h-10 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
            <h3 className="text-base font-medium text-gray-900 dark:text-white">Aucun résultat</h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">Essayez de modifier vos filtres.</p>
          </div>
        )}
      </div>
    </div>
  );
};
