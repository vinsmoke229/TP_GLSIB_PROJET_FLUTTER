import React, { useMemo, useState } from 'react';
import { DollarSign, Ticket, Users, Activity, Trophy, TrendingUp, Calendar, ArrowRight, Clock, Star, Zap, MoreHorizontal, ArrowUpRight, ArrowDownRight, Plus, ScanLine, FileDown } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';
import { Event, SalesData } from '../../types';

interface DashboardProps {
  events: Event[];
  salesData: SalesData[];
  onViewReports: () => void;
  onCreateEvent: () => void;
  adminInfo?: any;
}

export const Dashboard: React.FC<DashboardProps> = ({ events, salesData, onViewReports, onCreateEvent, adminInfo }) => {
  const [showQuickActions, setShowQuickActions] = useState(false);

  // Calculate total stats
  const stats = useMemo(() => {
    let totalRevenue = 0;
    let totalTickets = 0;
    let totalValidated = 0;

    events.forEach(e => {
      totalValidated += e.ticketsValidated;
      e.ticketTypes.forEach(t => {
        totalRevenue += t.price * t.quantitySold;
        totalTickets += t.quantitySold;
      });
    });

    return { totalRevenue, totalTickets, totalValidated };
  }, [events]);

  // Calculate top performing events
  const topEvents = useMemo(() => {
    return [...events]
      .map(event => {
        const revenue = event.ticketTypes.reduce((acc, t) => acc + (t.price * t.quantitySold), 0);
        const sold = event.ticketTypes.reduce((acc, t) => acc + t.quantitySold, 0);
        const total = event.ticketTypes.reduce((acc, t) => acc + t.quantityTotal, 0);
        return { ...event, revenue, sold, total };
      })
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 5);
  }, [events]);

  const currentDate = new Date().toLocaleDateString('fr-FR', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });

  return (
    <div className="space-y-4 sm:space-y-6 animation-fade-in">
      {/* Welcome Section */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-2">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 tracking-tight">Bonjour {adminInfo?.prenom}</h1>
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-1 flex items-center gap-2">
            <Calendar className="w-4 h-4" />
            {currentDate.charAt(0).toUpperCase() + currentDate.slice(1)}
          </p>
        </div>
        <div className="flex gap-3 relative">
          <button
            onClick={() => setShowQuickActions(!showQuickActions)}
            className="bg-gray-900 dark:bg-emerald-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-black dark:hover:bg-emerald-700 transition-colors shadow-lg shadow-gray-200 dark:shadow-none flex items-center gap-2 active:scale-95 transform duration-100"
          >
            <Zap className="w-4 h-4 fill-current" /> Actions Rapides
          </button>

          {showQuickActions && (
            <div className="absolute top-full right-0 mt-3 w-56 bg-white dark:bg-gray-800 rounded-xl shadow-2xl border border-gray-100 dark:border-gray-700 z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200 ring-1 ring-black/5">
              <div className="p-1.5 space-y-0.5">
                <button
                  onClick={() => { onCreateEvent(); setShowQuickActions(false); }}
                  className="w-full text-left px-3 py-2.5 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-white rounded-lg flex items-center gap-3 transition-all group cursor-pointer"
                >
                  <div className="p-1.5 bg-emerald-50 dark:bg-emerald-900/40 text-emerald-600 dark:text-emerald-400 rounded-md group-hover:bg-emerald-100 dark:group-hover:bg-emerald-900/60 transition-colors"><Plus className="w-4 h-4" /></div>
                  <span className="font-medium">Créer un événement</span>
                </button>
                <button
                  onClick={() => { onViewReports(); setShowQuickActions(false); }}
                  className="w-full text-left px-3 py-2.5 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-white rounded-lg flex items-center gap-3 transition-all group cursor-pointer"
                >
                  <div className="p-1.5 bg-purple-50 dark:bg-purple-900/40 text-purple-600 dark:text-purple-400 rounded-md group-hover:bg-purple-100 dark:group-hover:bg-purple-900/60 transition-colors"><FileDown className="w-4 h-4" /></div>
                  <span className="font-medium">Exporter les rapports</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Stats Grid - Resized for "Normal" Look */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {/* Revenue Card */}
        <div className="relative overflow-hidden bg-gradient-to-br from-emerald-500 to-teal-600 rounded-xl p-4 sm:p-5 text-white shadow-lg shadow-emerald-100 transition-transform hover:-translate-y-1 duration-300">
          <div className="absolute top-0 right-0 p-3 opacity-10"><DollarSign className="w-16 h-16" /></div>
          <div className="relative z-10">
            <p className="text-emerald-50 font-medium text-xs uppercase tracking-wider">Revenu Total</p>
            <h3 className="text-2xl font-bold mt-1 mb-1">{stats.totalRevenue.toLocaleString('fr-FR')} FCFA</h3>
            <div className="flex items-center gap-1 text-emerald-100 text-xs bg-white/10 w-fit px-1.5 py-0.5 rounded backdrop-blur-sm">
              <ArrowUpRight className="w-3 h-3" />
              <span>+12.5%</span>
            </div>
          </div>
        </div>

        {/* Tickets Card */}
        <div className="relative overflow-hidden bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl p-5 text-white shadow-lg shadow-blue-100 transition-transform hover:-translate-y-1 duration-300">
          <div className="absolute top-0 right-0 p-3 opacity-10"><Ticket className="w-16 h-16" /></div>
          <div className="relative z-10">
            <p className="text-blue-50 font-medium text-xs uppercase tracking-wider">Billets Vendus</p>
            <h3 className="text-2xl font-bold mt-1 mb-1">{stats.totalTickets.toLocaleString('fr-FR')}</h3>
            <div className="flex items-center gap-1 text-blue-100 text-xs bg-white/10 w-fit px-1.5 py-0.5 rounded backdrop-blur-sm">
              <ArrowUpRight className="w-3 h-3" />
              <span>+5.2%</span>
            </div>
          </div>
        </div>

        {/* Validated Card */}
        <div className="relative overflow-hidden bg-gradient-to-br from-purple-500 to-fuchsia-600 rounded-xl p-5 text-white shadow-lg shadow-purple-100 transition-transform hover:-translate-y-1 duration-300">
          <div className="absolute top-0 right-0 p-3 opacity-10"><Users className="w-16 h-16" /></div>
          <div className="relative z-10">
            <p className="text-purple-50 font-medium text-xs uppercase tracking-wider">Entrées Validées</p>
            <h3 className="text-2xl font-bold mt-1 mb-1">{stats.totalValidated.toLocaleString('fr-FR')}</h3>
            <div className="flex items-center gap-1 text-white text-xs bg-red-500 w-fit px-1.5 py-0.5 rounded shadow-sm animate-pulse">
              <div className="w-1.5 h-1.5 bg-white rounded-full"></div>
              <span>LIVE</span>
            </div>
          </div>
        </div>

        {/* Active Events Card */}
        <div className="relative overflow-hidden bg-gradient-to-br from-amber-400 to-orange-500 rounded-xl p-5 text-white shadow-lg shadow-orange-100 transition-transform hover:-translate-y-1 duration-300">
          <div className="absolute top-0 right-0 p-3 opacity-10"><Activity className="w-16 h-16" /></div>
          <div className="relative z-10">
            <p className="text-amber-50 font-medium text-xs uppercase tracking-wider">Évènements Actifs</p>
            <h3 className="text-2xl font-bold mt-1 mb-1">{events.filter(e => e.status === 'published').length}</h3>
            <div className="flex items-center gap-1 text-amber-100 text-xs bg-white/10 w-fit px-1.5 py-0.5 rounded backdrop-blur-sm">
              <Star className="w-3 h-3 fill-current" />
              <span>Top perf.</span>
            </div>
          </div>
        </div>
      </div>

      {/* Bento Grid Layout - Compacted */}
      <div className="grid grid-cols-1 lg:grid-cols-3 xl:grid-cols-4 gap-3 sm:gap-4 md:gap-6 auto-rows-[minmax(180px,auto)]">

        {/* Main Chart */}
        {/* Main Chart */}
        <div className="lg:col-span-2 xl:col-span-3 bg-white dark:bg-gray-800 p-5 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex flex-col h-[350px]">
          <div className="flex justify-between items-center mb-4">
            <div>
              <h2 className="text-lg font-bold text-gray-900 dark:text-gray-100">Aperçu des Ventes</h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">Revenus bruts sur les 30 derniers jours</p>
            </div>
            <div className="flex bg-gray-50 dark:bg-gray-700 p-1 rounded-lg border border-gray-100 dark:border-gray-600">
              <button className="px-2 py-1 bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm text-xs font-medium rounded-md">7J</button>
              <button className="px-2 py-1 text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white text-xs font-medium rounded-md">30J</button>
              <button className="px-2 py-1 text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white text-xs font-medium rounded-md">1A</button>
            </div>
          </div>
          <div className="flex-1 w-full min-h-0">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={salesData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fill: '#9ca3af', fontSize: 11 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#9ca3af', fontSize: 11 }} tickFormatter={(value) => `${value / 1000}k`} />
                <Tooltip
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', padding: '8px', fontSize: '12px' }}
                  formatter={(value: number) => [`${value} FCFA`, 'Revenu']}
                  cursor={{ stroke: '#10b981', strokeWidth: 1 }}
                />
                <Area type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Ticket Distribution */}
        <div className="bg-white dark:bg-gray-800 p-5 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex flex-col h-[350px]">
          <h2 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-1">Répartition</h2>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">Ventes par catégorie</p>
          <div className="flex-1 relative">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={[
                    { name: 'Standard', value: 650 },
                    { name: 'VIP', value: 95 },
                    { name: 'Early Bird', value: 500 },
                    { name: 'Regular', value: 320 }
                  ]}
                  cx="50%"
                  cy="50%"
                  innerRadius={55}
                  outerRadius={75}
                  paddingAngle={5}
                  dataKey="value"
                >
                  <Cell key="cell-0" fill="#10b981" />
                  <Cell key="cell-1" fill="#f59e0b" />
                  <Cell key="cell-2" fill="#3b82f6" />
                  <Cell key="cell-3" fill="#6366f1" />
                </Pie>
                <Tooltip contentStyle={{ borderRadius: '10px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', fontSize: '12px' }} />
                <Legend verticalAlign="bottom" height={36} iconType="circle" wrapperStyle={{ fontSize: '11px' }} />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none pb-8">
              <div className="text-center">
                <span className="block text-2xl font-bold text-gray-900 dark:text-white">{stats.totalTickets}</span>
                <span className="text-[10px] text-gray-500 dark:text-gray-400 font-medium uppercase tracking-wide">Billets</span>
              </div>
            </div>
          </div>
        </div>

        {/* Recent Activity Feed */}
        <div className="lg:col-span-2 bg-white dark:bg-gray-800 p-5 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex flex-col">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
              <Clock className="w-4 h-4 text-gray-400" /> Activité Récente
            </h2>
            <button className="text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300 text-xs font-medium">Tout voir</button>
          </div>

          <div className="space-y-4">
            {[
              { id: 1, user: 'Alice Admin', action: 'a créé l\'événement', target: 'Summer Vibes Festival', time: 'Il y a 2h', avatar: 'https://i.pravatar.cc/150?u=1' },
              { id: 2, user: 'Nouveau Client', action: 'a acheté 2 billets VIP', target: 'Tech Summit 2024', time: 'Il y a 15m', avatar: 'https://i.pravatar.cc/150?u=12' },
              { id: 3, user: 'Système', action: 'Validation automatique', target: 'Mise à jour des analyses', time: 'Il y a 5m', avatar: 'https://ui-avatars.com/api/?name=System&background=10b981&color=fff' },
              { id: 4, user: 'Laura Scan', action: 'a scanné le billet #8942 de', target: 'Marc Dupont', time: 'À l\'instant', avatar: 'https://i.pravatar.cc/150?u=24' },
            ].map((activity, idx) => (
              <div key={activity.id} className="flex gap-3 items-center group p-2 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-lg transition-colors -mx-2">
                <img src={activity.avatar} alt="" className="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-700 object-cover border border-gray-200 dark:border-gray-600" />
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-gray-900 dark:text-gray-100 truncate">
                    <span className="font-semibold">{activity.user}</span> <span className="text-gray-500 dark:text-gray-400">{activity.action}</span>
                  </p>
                  <p className="text-[10px] font-medium text-emerald-600 dark:text-emerald-400 truncate">{activity.target}</p>
                </div>
                <span className="text-[10px] text-gray-400 shrink-0 whitespace-nowrap">{activity.time}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Top Events List */}
        <div className="lg:col-span-1 xl:col-span-2 bg-white dark:bg-gray-800 p-5 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex flex-col">
          <h2 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-4 flex items-center gap-2">
            <Trophy className="w-4 h-4 text-amber-500" />
            Top Performances
          </h2>

          <div className="flex-1 space-y-3">
            {topEvents.map((event, index) => (
              <div key={event.id} className="flex items-center gap-3 p-2.5 bg-gray-50 dark:bg-gray-700 hover:bg-white dark:hover:bg-gray-600 hover:shadow-sm rounded-lg transition-all group border border-transparent hover:border-gray-100 dark:hover:border-gray-600">
                <div className="relative shrink-0">
                  <div className="w-10 h-10 rounded-md overflow-hidden bg-gray-200">
                    <img src={event.imageUrl} alt={event.title} className="w-full h-full object-cover" />
                  </div>
                  <div className={`absolute -top-1.5 -left-1.5 w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold border-2 border-white
                      ${index === 0 ? 'bg-yellow-400 text-white shadow-sm' :
                      index === 1 ? 'bg-gray-300 text-white shadow-sm' :
                        index === 2 ? 'bg-amber-600 text-white shadow-sm' : 'bg-gray-100 text-gray-500'}
                    `}>
                    {index + 1}
                  </div>
                </div>

                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-gray-900 dark:text-gray-100 truncate text-xs">{event.title}</h3>
                  <div className="flex items-center gap-1.5 text-[10px] text-gray-500 dark:text-gray-400 mt-0.5">
                    <Calendar className="w-2.5 h-2.5" />
                    <span>{new Date(event.date).toLocaleDateString()}</span>
                  </div>
                </div>

                <div className="text-right shrink-0">
                  <p className="font-bold text-gray-900 dark:text-gray-100 text-xs">{event.revenue.toLocaleString()} FCFA</p>
                  <div className="text-[10px] font-medium px-1.5 py-0 rounded-full bg-emerald-100 text-emerald-700 inline-block mt-0.5">
                    {event.sold} ventes
                  </div>
                </div>
              </div>
            ))}
          </div>

          <button
            onClick={onViewReports}
            className="mt-4 w-full py-2.5 text-xs text-gray-600 dark:text-gray-300 font-medium border border-gray-200 dark:border-gray-600 rounded-lg hover:bg-gray-900 dark:hover:bg-gray-700 hover:text-white transition-all flex items-center justify-center gap-2 group shadow-sm">
            Voir le rapport complet
            <ArrowRight className="w-3 h-3 transition-transform group-hover:translate-x-1" />
          </button>
        </div>

      </div>
    </div>
  );
};
