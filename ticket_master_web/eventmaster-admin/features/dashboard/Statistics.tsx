import React, { useMemo, useState, useRef } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell, Legend } from 'recharts';
import { DollarSign, Ticket, TrendingUp, Users, Calendar, Download, Filter, ChevronDown, AlertTriangle, PieChart as PieChartIcon } from 'lucide-react';
import { SalesData, Event } from '../../types';
import html2canvas from 'html2canvas';
import logo from '../../assets/logo.jpg';

interface StatisticsProps {
    salesData: SalesData[];
    events: Event[];
}

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444'];

export const Statistics: React.FC<StatisticsProps> = ({ salesData, events }) => {
    const [dateRange, setDateRange] = useState<'week' | 'month' | 'year' | 'all'>('all');
    const [statusFilter, setStatusFilter] = useState<'all' | 'published' | 'ended'>('all');
    const [showAllTopEvents, setShowAllTopEvents] = useState(false);
    const exportRef = useRef<HTMLDivElement>(null);

    // Filter Logic
    const filteredEvents = useMemo(() => {
        let filtered = events;

        // Status Filter
        if (statusFilter !== 'all') {
            // Assuming 'ended' status for events that are not 'published' and have a past date
            if (statusFilter === 'ended') {
                filtered = filtered.filter(e => e.status !== 'published' && new Date(e.date) < new Date());
            } else {
                filtered = filtered.filter(e => e.status === statusFilter);
            }
        }

        // Date Range Filter (Simulated logic based on event date for this mock)
        const now = new Date();
        if (dateRange !== 'all') {
            const cutoffDate = new Date();
            if (dateRange === 'week') cutoffDate.setDate(now.getDate() - 7);
            if (dateRange === 'month') cutoffDate.setMonth(now.getMonth() - 1);
            if (dateRange === 'year') cutoffDate.setFullYear(now.getFullYear() - 1);

            filtered = filtered.filter(e => new Date(e.date) >= cutoffDate);
        }

        return filtered;
    }, [events, statusFilter, dateRange]);

    // Advanced calculations based on filtered events
    const stats = useMemo(() => {
        const totalRevenue = filteredEvents.reduce((acc, e) => acc + e.ticketTypes.reduce((sum, t) => sum + (t.price * t.quantitySold), 0), 0);
        const totalTicketsSold = filteredEvents.reduce((acc, e) => acc + e.ticketTypes.reduce((sum, t) => sum + t.quantitySold, 0), 0);
        const totalCapacity = filteredEvents.reduce((acc, e) => acc + e.ticketTypes.reduce((sum, t) => sum + t.quantityTotal, 0), 0);
        const occupancyRate = totalCapacity > 0 ? (totalTicketsSold / totalCapacity) * 100 : 0;
        const fraudulentTickets = events.filter(e => new Date(e.date) < new Date()).reduce((acc, e) => acc + e.ticketsValidated, 0);

        return { totalRevenue, totalTicketsSold, occupancyRate, totalCapacity, fraudulentTickets };
    }, [filteredEvents, events]);

    const ticketTypeData = useMemo(() => {
        const typeMap: Record<string, number> = {};
        filteredEvents.forEach(e => {
            e.ticketTypes.forEach(t => {
                if (typeMap[t.name]) {
                    typeMap[t.name] += t.quantitySold;
                } else {
                    typeMap[t.name] = t.quantitySold;
                }
            });
        });
        return Object.keys(typeMap).map(name => ({ name, value: typeMap[name] }));
    }, [filteredEvents]);

    const topEvents = useMemo(() => {
        return [...filteredEvents].sort((a, b) => {
            const revA = a.ticketTypes.reduce((sum, t) => sum + (t.price * t.quantitySold), 0);
            const revB = b.ticketTypes.reduce((sum, t) => sum + (t.price * t.quantitySold), 0);
            return revB - revA;
        });
    }, [filteredEvents]);

    const displayedTopEvents = showAllTopEvents ? topEvents : topEvents.slice(0, 3);

    const handleExport = async () => {
        // Create a temporary container for the report
        const reportContainer = document.createElement('div');
        reportContainer.style.position = 'absolute';
        reportContainer.style.top = '-9999px';
        reportContainer.style.left = '0';
        reportContainer.style.width = '800px'; // A4 width approx
        reportContainer.style.backgroundColor = '#ffffff';
        reportContainer.style.zIndex = '-1';
        document.body.appendChild(reportContainer);

        // We need to render the ReportTemplate into this container.
        // Since we are continuously in React, we can't easily ReactDOM.render without extra setup.
        // Easier approach: Keep the report container in the main JSX but hidden, and reference it.

        if (exportRef.current) {
            try {
                // Ensure ref is visible specifically for capture if using the in-DOM hidden approach
                const canvas = await html2canvas(exportRef.current, {
                    scale: 2,
                    useCORS: true,
                    backgroundColor: '#ffffff', // Force white background for report
                    windowWidth: 1200 // Ensure desktop layout
                });

                const image = canvas.toDataURL("image/png");
                const link = document.createElement("a");
                link.href = image;
                link.download = `rapport_statistiques_${new Date().toISOString().slice(0, 10)}.png`;
                link.click();
            } catch (error) {
                console.error("Export failed:", error);
                alert("L'exportation a échoué.");
            }
        }
    };

    return (
        <div className="space-y-6 animation-fade-in p-2 pb-10">
            {/* Hidden Report Container for HTML2Canvas */}
            <div style={{ position: 'absolute', top: '-9999px', left: '-9999px' }}>
                <div ref={exportRef}>
                    <ReportLayout stats={stats} events={filteredEvents} salesData={salesData} />
                </div>
            </div>

            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
                            <PieChartIcon className="w-6 h-6 text-white" />
                        </div>
                        Statistiques Détaillées
                    </h1>
                    <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Analysez la performance de vos événements en temps réel
                    </p>
                </div>

                <div className="flex flex-wrap gap-3">
                    {/* Date Range Filter */}
                    <div className="relative">
                        <select
                            value={dateRange}
                            onChange={(e) => setDateRange(e.target.value as any)}
                            className="appearance-none bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-200 py-2 pl-4 pr-10 rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500/20 shadow-sm cursor-pointer"
                        >
                            <option value="all">Toute la période</option>
                            <option value="week">Derniers 7 jours</option>
                            <option value="month">Derniers 30 jours</option>
                            <option value="year">Cette année</option>
                        </select>
                        <ChevronDown className="w-4 h-4 text-gray-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    </div>

                    {/* Status Filter */}
                    <div className="relative">
                        <select
                            value={statusFilter}
                            onChange={(e) => setStatusFilter(e.target.value as any)}
                            className="appearance-none bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-200 py-2 pl-4 pr-10 rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500/20 shadow-sm cursor-pointer"
                        >
                            <option value="all">Tous les statuts</option>
                            <option value="published">En ligne</option>
                            <option value="ended">Terminé</option>
                        </select>
                        <Filter className="w-4 h-4 text-gray-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    </div>

                    <button
                        onClick={handleExport}
                        className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700 shadow-md shadow-emerald-600/20 transition-all active:scale-95"
                    >
                        <Download className="w-4 h-4" />
                        Exporter le rapport
                    </button>
                </div>
            </div>

            {/* KPI Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all group">
                    <div className="flex justify-between items-start">
                        <div>
                            <p className="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-wider">Revenus Totaux</p>
                            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{stats.totalRevenue.toLocaleString()} FCFA</h3>
                        </div>
                        <div className="p-2 bg-emerald-50 dark:bg-emerald-900/30 rounded-lg group-hover:bg-emerald-100 dark:group-hover:bg-emerald-900/50 transition-colors">
                            <DollarSign className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                        </div>
                    </div>
                    <div className="mt-4 flex items-center gap-2 text-sm text-emerald-600 dark:text-emerald-400 font-medium">
                        <TrendingUp className="w-4 h-4" />
                        <span className="bg-emerald-50 dark:bg-emerald-900/30 px-1.5 py-0.5 rounded text-xs">+12.5%</span>
                        <span className="text-gray-400 font-normal text-xs ml-auto">vs mois dernier</span>
                    </div>
                </div>

                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all group">
                    <div className="flex justify-between items-start">
                        <div>
                            <p className="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-wider">Billets Vendus</p>
                            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{stats.totalTicketsSold}</h3>
                        </div>
                        <div className="p-2 bg-blue-50 dark:bg-blue-900/30 rounded-lg group-hover:bg-blue-100 dark:group-hover:bg-blue-900/50 transition-colors">
                            <Ticket className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                        </div>
                    </div>
                    <div className="mt-4 flex items-center gap-2 text-sm text-blue-600 dark:text-blue-400 font-medium">
                        <TrendingUp className="w-4 h-4" />
                        <span className="bg-blue-50 dark:bg-blue-900/30 px-1.5 py-0.5 rounded text-xs">+8.2%</span>
                        <span className="text-gray-400 font-normal text-xs ml-auto">vs mois dernier</span>
                    </div>
                </div>

                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all group">
                    <div className="flex justify-between items-start">
                        <div>
                            <p className="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-wider">Taux de Remplissage</p>
                            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{stats.occupancyRate.toFixed(1)}%</h3>
                        </div>
                        <div className="p-2 bg-purple-50 dark:bg-purple-900/30 rounded-lg group-hover:bg-purple-100 dark:group-hover:bg-purple-900/50 transition-colors">
                            <Users className="w-5 h-5 text-purple-600 dark:text-purple-400" />
                        </div>
                    </div>
                    <div className="mt-4 flex items-center gap-2 text-sm">
                        <span className="w-full bg-gray-100 dark:bg-gray-700 h-2 rounded-full overflow-hidden">
                            <div className="h-full bg-purple-500 rounded-full" style={{ width: `${stats.occupancyRate}%` }}></div>
                        </span>
                    </div>
                </div>

                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all group">
                    <div className="flex justify-between items-start">
                        <div>
                            <p className="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-wider">Billets Frauduleux</p>
                            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{stats.fraudulentTickets}</h3>
                        </div>
                        <div className="p-2 bg-red-50 dark:bg-red-900/30 rounded-lg group-hover:bg-red-100 dark:group-hover:bg-red-900/50 transition-colors">
                            <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400" />
                        </div>
                    </div>
                    <div className="mt-4 flex items-center gap-2 text-sm text-red-600 dark:text-red-400 font-medium">
                        <span className="text-gray-400 font-normal text-xs">Billets validés sur événements passés</span>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Main Sales Chart - Note: MockSalesData is static, ideally filter this too if it had granular real dates */}
                <div className="lg:col-span-2 bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white">Évolution des Ventes</h2>
                    </div>
                    <div className="h-[300px]">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={salesData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                                <defs>
                                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#10b981" stopOpacity={0.2} />
                                        <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" className="dark:stroke-gray-700" />
                                <XAxis dataKey="date" stroke="#9ca3af" fontSize={12} tickLine={false} axisLine={false} />
                                <YAxis stroke="#9ca3af" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `${value} FCFA`} />
                                <Tooltip
                                    contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                                    formatter={(value: number) => [`${value} FCFA`, 'Revenu']}
                                />
                                <Area type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Ticket Types Pie Chart */}
                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
                    <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-6">Répartition par Ticket</h2>
                    <div className="h-[300px] flex items-center justify-center">
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie
                                    data={ticketTypeData}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={90}
                                    paddingAngle={5}
                                    dataKey="value"
                                >
                                    {ticketTypeData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} stroke="none" />
                                    ))}
                                </Pie>
                                <Tooltip contentStyle={{ borderRadius: '8px' }} />
                                <Legend verticalAlign="bottom" height={36} iconType="circle" />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            </div>

            {/* Top Events Table */}
            <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-lg font-bold text-gray-900 dark:text-white">Top Performances Événementielles</h2>
                    {topEvents.length > 3 && (
                        <button
                            onClick={() => setShowAllTopEvents(!showAllTopEvents)}
                            className="text-sm font-medium text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300 transition-colors"
                        >
                            {showAllTopEvents ? 'Voir moins' : `Voir plus (${topEvents.length})`}
                        </button>
                    )}
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-100 dark:border-gray-700">
                                <th className="text-left py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Événement</th>
                                <th className="text-left py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Date</th>
                                <th className="text-right py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Billets Vendus</th>
                                <th className="text-right py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Revenu</th>
                                <th className="text-right py-3 px-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Statut</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
                            {displayedTopEvents.map((event) => {
                                const revenue = event.ticketTypes.reduce((sum, t) => sum + (t.price * t.quantitySold), 0);
                                const sold = event.ticketTypes.reduce((sum, t) => sum + t.quantitySold, 0);

                                return (
                                    <tr key={event.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                                        <td className="py-3 px-4">
                                            <div className="flex items-center gap-3">
                                                <img src={event.imageUrl} alt={event.title} className="w-10 h-10 rounded-lg object-cover" />
                                                <span className="font-medium text-gray-900 dark:text-white">{event.title}</span>
                                            </div>
                                        </td>
                                        <td className="py-3 px-4 text-sm text-gray-500 dark:text-gray-400">{event.date}</td>
                                        <td className="py-3 px-4 text-sm text-right font-medium text-gray-900 dark:text-gray-200">{sold}</td>
                                        <td className="py-3 px-4 text-sm text-right font-bold text-emerald-600 dark:text-emerald-400">{revenue.toLocaleString()} FCFA</td>
                                        <td className="py-3 px-4 text-right">
                                            <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${event.status === 'published' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' :
                                                event.status === 'draft' ? 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300' :
                                                    'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400'
                                                }`}>
                                                {event.status === 'published' ? 'En ligne' : event.status === 'draft' ? 'Brouillon' : 'Terminé'}
                                            </span>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

// Formal Report Template (Hidden in UI, rendered for export)
const ReportLayout = ({ stats, events, salesData }: { stats: any, events: Event[], salesData: SalesData[] }) => {
    return (
        <div className="bg-white text-gray-900 p-10 font-serif w-[1000px] mx-auto min-h-[1414px]">
            {/* Header */}
            <div className="flex justify-between items-center border-b-2 border-gray-900 pb-6 mb-8">
                <div className="flex items-center gap-4">
                    <img src={logo} alt="Logo" className="h-16 w-auto" />
                    <div>
                        <h1 className="text-3xl font-bold uppercase tracking-wider">Rapport de Performance</h1>
                        <p className="text-sm text-gray-500">Généré le {new Date().toLocaleDateString()}</p>
                    </div>
                </div>
                <div className="text-right">
                    <p className="font-bold">EventMaster Inc.</p>
                    <p className="text-sm text-gray-600">Confidentialité: Interne</p>
                </div>
            </div>

            {/* Executive Summary */}
            <div className="mb-10">
                <h2 className="text-xl font-bold mb-4 uppercase text-emerald-800 border-l-4 border-emerald-600 pl-3">Vue d'ensemble Exécutive</h2>
                <p className="mb-6 text-gray-700 leading-relaxed text-justify">
                    Ce rapport présente une analyse détaillée des performances de la plateforme EventMaster pour la période en cours.
                    Avec un chiffre d'affaires total de <span className="font-bold">{stats.totalRevenue.toLocaleString()} FCFA</span> et <span className="font-bold">{stats.totalTicketsSold}</span> billets vendus,
                    l'activité démontre une dynamique solide. Le taux de remplissage global s'établit à <span className="font-bold">{stats.occupancyRate.toFixed(1)}%</span>,
                    reflétant l'efficacité de nos campagnes d'acquisition actuelles.
                </p>

                <div className="grid grid-cols-3 gap-6">
                    <div className="border border-gray-200 p-4 rounded-lg bg-gray-50">
                        <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Revenus</p>
                        <p className="text-3xl font-bold text-gray-900">{stats.totalRevenue.toLocaleString()} FCFA</p>
                    </div>
                    <div className="border border-gray-200 p-4 rounded-lg bg-gray-50">
                        <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Billets Vendus</p>
                        <p className="text-3xl font-bold text-gray-900">{stats.totalTicketsSold}</p>
                    </div>
                    <div className="border border-gray-200 p-4 rounded-lg bg-gray-50">
                        <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Remplissage</p>
                        <p className="text-3xl font-bold text-gray-900">{stats.occupancyRate.toFixed(1)}%</p>
                    </div>
                </div>
            </div>

            {/* Detailed Events Table */}
            <div className="mb-10">
                <h2 className="text-xl font-bold mb-4 uppercase text-blue-800 border-l-4 border-blue-600 pl-3">Détail des Performances par Événement</h2>
                <table className="w-full border-collapse border border-gray-300 text-sm">
                    <thead className="bg-gray-100">
                        <tr>
                            <th className="border border-gray-300 px-4 py-2 text-left uppercase text-xs">Événement</th>
                            <th className="border border-gray-300 px-4 py-2 text-center uppercase text-xs">Date</th>
                            <th className="border border-gray-300 px-4 py-2 text-right uppercase text-xs">Ventes</th>
                            <th className="border border-gray-300 px-4 py-2 text-right uppercase text-xs">Revenu</th>
                            <th className="border border-gray-300 px-4 py-2 text-center uppercase text-xs">Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        {events.map((e, idx) => {
                            const rev = e.ticketTypes.reduce((s, t) => s + (t.price * t.quantitySold), 0);
                            const sold = e.ticketTypes.reduce((s, t) => s + t.quantitySold, 0);
                            return (
                                <tr key={e.id} className={idx % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                                    <td className="border border-gray-300 px-4 py-2 font-medium">{e.title}</td>
                                    <td className="border border-gray-300 px-4 py-2 text-center">{e.date}</td>
                                    <td className="border border-gray-300 px-4 py-2 text-right">{sold}</td>
                                    <td className="border border-gray-300 px-4 py-2 text-right font-bold">{rev.toLocaleString()} FCFA</td>
                                    <td className="border border-gray-300 px-4 py-2 text-center text-xs uppercase">{e.status}</td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>

            {/* Footer */}
            <div className="mt-auto pt-8 border-t border-gray-300 flex justify-between text-xs text-gray-500">
                <p>EventMaster - Plateforme de Gestion Événementielle</p>
                <p>Ce document est confidentiel et destiné à un usage interne uniquement.</p>
            </div>
        </div>
    );
};
