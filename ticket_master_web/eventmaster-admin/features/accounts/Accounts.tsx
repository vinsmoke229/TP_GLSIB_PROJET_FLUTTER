import React, { useState, useMemo, useRef } from 'react';
import { Wallet, TrendingUp, TrendingDown, Search, Download, Eye, ArrowUpRight, ArrowDownRight, CreditCard, ChevronLeft, ChevronRight, SlidersHorizontal, X } from 'lucide-react';
import html2canvas from 'html2canvas';
import logo from '../../assets/logo.jpg';

interface Transaction {
  id: string;
  date: string;
  type: 'credit' | 'debit';
  amount: number;
  description: string;
  status: 'completed' | 'pending' | 'failed';
}

interface ClientAccount {
  id: string;
  clientName: string;
  email: string;
  balance: number;
  totalSpent: number;
  totalTransactions: number;
  avatar: string;
  transactions: Transaction[];
}

const mockAccounts: ClientAccount[] = [
  {
    id: '1',
    clientName: 'Marie Dubois',
    email: 'marie.dubois@email.com',
    balance: 1250.50,
    totalSpent: 3450.00,
    totalTransactions: 12,
    avatar: 'https://i.pravatar.cc/150?u=marie',
    transactions: [
      { id: 't1', date: '2024-01-15', type: 'debit', amount: 120, description: 'Achat billet - Jazz Festival', status: 'completed' },
      { id: 't2', date: '2024-01-10', type: 'credit', amount: 500, description: 'Rechargement compte', status: 'completed' },
      { id: 't3', date: '2024-01-05', type: 'debit', amount: 250, description: 'Achat billet VIP - Tech Summit', status: 'completed' },
    ]
  },
  {
    id: '2',
    clientName: 'Jean Martin',
    email: 'jean.martin@email.com',
    balance: 450.00,
    totalSpent: 2100.00,
    totalTransactions: 8,
    avatar: 'https://i.pravatar.cc/150?u=jean',
    transactions: [
      { id: 't4', date: '2024-01-14', type: 'debit', amount: 80, description: 'Achat billet - Concert', status: 'completed' },
      { id: 't5', date: '2024-01-12', type: 'credit', amount: 300, description: 'Rechargement compte', status: 'completed' },
    ]
  },
  {
    id: '3',
    clientName: 'Sophie Laurent',
    email: 'sophie.laurent@email.com',
    balance: 2100.75,
    totalSpent: 5600.00,
    totalTransactions: 18,
    avatar: 'https://i.pravatar.cc/150?u=sophie',
    transactions: [
      { id: 't6', date: '2024-01-16', type: 'debit', amount: 150, description: 'Achat billet - Festival', status: 'pending' },
      { id: 't7', date: '2024-01-13', type: 'credit', amount: 1000, description: 'Rechargement compte', status: 'completed' },
      { id: 't8', date: '2024-01-08', type: 'debit', amount: 200, description: 'Achat billet VIP', status: 'completed' },
    ]
  },
];

export const Accounts: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAccount, setSelectedAccount] = useState<ClientAccount | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(20);
  const [balanceFilter, setBalanceFilter] = useState<'all' | 'positive' | 'low'>('all');
  const [sortBy, setSortBy] = useState<'name' | 'balance' | 'spent'>('name');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc');
  const [showFilters, setShowFilters] = useState(false);
  const [transactionStartDate, setTransactionStartDate] = useState('');
  const [transactionEndDate, setTransactionEndDate] = useState('');
  const exportRef = useRef<HTMLDivElement>(null);
  const accountDetailRef = useRef<HTMLDivElement>(null);

  const filteredAndSortedAccounts = useMemo(() => {
    let filtered = mockAccounts.filter(account => {
      const matchesSearch = account.clientName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        account.email.toLowerCase().includes(searchTerm.toLowerCase());
      
      const matchesBalance = balanceFilter === 'all' ||
        (balanceFilter === 'positive' && account.balance > 500) ||
        (balanceFilter === 'low' && account.balance <= 500);
      
      return matchesSearch && matchesBalance;
    });

    filtered.sort((a, b) => {
      let comparison = 0;
      if (sortBy === 'name') comparison = a.clientName.localeCompare(b.clientName);
      else if (sortBy === 'balance') comparison = a.balance - b.balance;
      else if (sortBy === 'spent') comparison = a.totalSpent - b.totalSpent;
      return sortOrder === 'asc' ? comparison : -comparison;
    });

    return filtered;
  }, [searchTerm, balanceFilter, sortBy, sortOrder]);

  const totalPages = Math.ceil(filteredAndSortedAccounts.length / itemsPerPage);
  const paginatedAccounts = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return filteredAndSortedAccounts.slice(start, start + itemsPerPage);
  }, [filteredAndSortedAccounts, currentPage, itemsPerPage]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
      case 'pending': return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400';
      case 'failed': return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'completed': return 'Complété';
      case 'pending': return 'En attente';
      case 'failed': return 'Échoué';
      default: return status;
    }
  };

  const exportToImage = async () => {
    if (exportRef.current) {
      try {
        const canvas = await html2canvas(exportRef.current, {
          scale: 2,
          useCORS: true,
          backgroundColor: '#ffffff',
          windowWidth: 1200
        });

        const image = canvas.toDataURL("image/png");
        const link = document.createElement("a");
        link.href = image;
        link.download = `rapport_comptes_${new Date().toISOString().slice(0, 10)}.png`;
        link.click();
      } catch (error) {
        console.error("Export failed:", error);
        alert("L'exportation a échoué.");
      }
    }
  };

  const exportAccountToImage = async () => {
    if (accountDetailRef.current) {
      try {
        const canvas = await html2canvas(accountDetailRef.current, {
          scale: 2,
          useCORS: true,
          backgroundColor: '#ffffff',
          windowWidth: 1200
        });
        
        const image = canvas.toDataURL("image/png");
        const link = document.createElement("a");
        link.href = image;
        link.download = `compte_${selectedAccount?.clientName.replace(/\s+/g, '_')}_${new Date().toISOString().slice(0, 10)}.png`;
        link.click();
      } catch (error) {
        console.error("Export failed:", error);
        alert("L'exportation a échoué.");
      }
    }
  };

  const totalBalance = mockAccounts.reduce((sum, acc) => sum + acc.balance, 0);
  const totalSpent = mockAccounts.reduce((sum, acc) => sum + acc.totalSpent, 0);

  return (
    <div className="space-y-6">
      {/* Hidden Report for Export */}
      <div style={{ position: 'absolute', top: '-9999px', left: '-9999px' }}>
        <div ref={exportRef}>
          <AccountsReport accounts={filteredAndSortedAccounts} totalBalance={totalBalance} totalSpent={totalSpent} />
        </div>
        {selectedAccount && (
          <div ref={accountDetailRef}>
            <AccountDetailReport account={selectedAccount} filteredTransactions={selectedAccount.transactions.filter(transaction => {
              const transactionDate = new Date(transaction.date);
              const start = transactionStartDate ? new Date(transactionStartDate) : null;
              const end = transactionEndDate ? new Date(transactionEndDate) : null;
              return (!start || transactionDate >= start) && (!end || transactionDate <= end);
            })} formatCurrency={formatCurrency} getStatusLabel={getStatusLabel} />
          </div>
        )}
      </div>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
              <Wallet className="w-6 h-6 text-white" />
            </div>
            Comptes Clients
          </h1>
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
            Gérez les soldes et transactions de vos clients
          </p>
        </div>
        <button onClick={exportToImage} className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl transition-colors text-sm font-medium">
          <Download className="w-4 h-4" />
          Exporter
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <p className="text-sm text-gray-600 dark:text-gray-400">Solde Total</p>
            <Wallet className="w-5 h-5 text-blue-600" />
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{formatCurrency(totalBalance)}</p>
          <p className="text-xs text-green-600 mt-1 flex items-center gap-1">
            <TrendingUp className="w-3 h-3" /> +12.5% ce mois
          </p>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <p className="text-sm text-gray-600 dark:text-gray-400">Dépenses Totales</p>
            <TrendingDown className="w-5 h-5 text-purple-600" />
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{formatCurrency(totalSpent)}</p>
          <p className="text-xs text-gray-500 mt-1">{mockAccounts.length} comptes actifs</p>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <p className="text-sm text-gray-600 dark:text-gray-400">Transactions</p>
            <CreditCard className="w-5 h-5 text-emerald-600" />
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
            {mockAccounts.reduce((sum, acc) => sum + acc.totalTransactions, 0)}
          </p>
          <p className="text-xs text-emerald-600 mt-1 flex items-center gap-1">
            <TrendingUp className="w-3 h-3" /> +8.2% ce mois
          </p>
        </div>
      </div>

      {/* Search & Filters Bar */}
      <div className="bg-white dark:bg-gray-800 p-4 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm space-y-3">
        <div className="flex gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Rechercher par nom ou email..."
              className="w-full pl-9 pr-4 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <button 
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              showFilters ? 'bg-blue-600 text-white' : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300'
            }`}
          >
            <SlidersHorizontal className="w-4 h-4" />
            Filtres
          </button>
        </div>

        {showFilters && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 pt-3 border-t border-gray-200 dark:border-gray-700">
            <div>
              <label className="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1 block">Solde</label>
              <select
                value={balanceFilter}
                onChange={(e) => setBalanceFilter(e.target.value as any)}
                className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">Tous les soldes</option>
                <option value="positive">Solde &gt; 500€</option>
                <option value="low">Solde ≤ 500€</option>
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1 block">Trier par</label>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as any)}
                className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="name">Nom</option>
                <option value="balance">Solde</option>
                <option value="spent">Dépenses</option>
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1 block">Ordre</label>
              <select
                value={sortOrder}
                onChange={(e) => setSortOrder(e.target.value as any)}
                className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="asc">Croissant</option>
                <option value="desc">Décroissant</option>
              </select>
            </div>
          </div>
        )}

        <div className="flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
          <span>{filteredAndSortedAccounts.length} compte(s) trouvé(s)</span>
          <span>Page {currentPage} sur {totalPages}</span>
        </div>
      </div>

      {/* Accounts Table */}
      <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 dark:bg-gray-900/50 border-b border-gray-200 dark:border-gray-700">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Client</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Email</th>
                <th className="px-6 py-3 text-right text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Solde</th>
                <th className="px-6 py-3 text-right text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Dépensé</th>
                <th className="px-6 py-3 text-center text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Transactions</th>
                <th className="px-6 py-3 text-center text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {paginatedAccounts.map((account) => (
                <tr key={account.id} className="hover:bg-gray-50 dark:hover:bg-gray-900/30 transition-colors">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center gap-3">
                      <img src={account.avatar} alt={account.clientName} className="w-10 h-10 rounded-full" />
                      <span className="font-medium text-gray-900 dark:text-gray-100">{account.clientName}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-400">{account.email}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <span className="font-bold text-blue-600">{formatCurrency(account.balance)}</span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <span className="font-semibold text-gray-900 dark:text-gray-100">{formatCurrency(account.totalSpent)}</span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-400">
                      {account.totalTransactions}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center">
                    <button
                      onClick={() => {
                        setSelectedAccount(account);
                        setShowModal(true);
                      }}
                      className="inline-flex items-center gap-1 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-medium rounded-lg transition-colors"
                    >
                      <Eye className="w-3 h-3" />
                      Détails
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-2">
          <button
            onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
            disabled={currentPage === 1}
            className="p-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          
          {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
            let pageNum;
            if (totalPages <= 5) {
              pageNum = i + 1;
            } else if (currentPage <= 3) {
              pageNum = i + 1;
            } else if (currentPage >= totalPages - 2) {
              pageNum = totalPages - 4 + i;
            } else {
              pageNum = currentPage - 2 + i;
            }
            
            return (
              <button
                key={pageNum}
                onClick={() => setCurrentPage(pageNum)}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  currentPage === pageNum
                    ? 'bg-blue-600 text-white'
                    : 'border border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800'
                }`}
              >
                {pageNum}
              </button>
            );
          })}
          
          <button
            onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
            disabled={currentPage === totalPages}
            className="p-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Modal Details */}
      {showModal && selectedAccount && (() => {
        const filteredTransactions = selectedAccount.transactions.filter(transaction => {
          const transactionDate = new Date(transaction.date);
          const start = transactionStartDate ? new Date(transactionStartDate) : null;
          const end = transactionEndDate ? new Date(transactionEndDate) : null;
          return (!start || transactionDate >= start) && (!end || transactionDate <= end);
        });

        return (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={() => setShowModal(false)}>
          <div data-modal-export className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden" onClick={(e) => e.stopPropagation()}>
            {/* Modal Header */}
            <div className="bg-gradient-to-r from-blue-500 to-indigo-600 p-6 text-white">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-2xl font-bold">Détails du Compte</h2>
                <button onClick={() => setShowModal(false)} className="p-2 hover:bg-white/20 rounded-lg transition-colors">
                  <X className="w-5 h-5" />
                </button>
              </div>
              <div className="flex items-center gap-4">
                <img src={selectedAccount.avatar} alt={selectedAccount.clientName} className="w-16 h-16 rounded-full border-4 border-white/30" />
                <div>
                  <h3 className="text-xl font-bold">{selectedAccount.clientName}</h3>
                  <p className="text-blue-100">{selectedAccount.email}</p>
                </div>
              </div>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto max-h-[calc(90vh-200px)]">
              {/* Stats Grid */}
              <div className="grid grid-cols-3 gap-4 mb-6">
                <div className="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-4 text-center">
                  <p className="text-xs text-blue-600 dark:text-blue-400 font-medium mb-1">Solde Actuel</p>
                  <p className="text-2xl font-bold text-blue-600">{formatCurrency(selectedAccount.balance)}</p>
                </div>
                <div className="bg-purple-50 dark:bg-purple-900/20 rounded-xl p-4 text-center">
                  <p className="text-xs text-purple-600 dark:text-purple-400 font-medium mb-1">Total Dépensé</p>
                  <p className="text-2xl font-bold text-purple-600">{formatCurrency(selectedAccount.totalSpent)}</p>
                </div>
                <div className="bg-emerald-50 dark:bg-emerald-900/20 rounded-xl p-4 text-center">
                  <p className="text-xs text-emerald-600 dark:text-emerald-400 font-medium mb-1">Transactions</p>
                  <p className="text-2xl font-bold text-emerald-600">{selectedAccount.totalTransactions}</p>
                </div>
              </div>

              {/* Date Filter */}
              <div className="bg-gray-50 dark:bg-gray-900/50 rounded-xl p-4 mb-4">
                <div className="flex items-center gap-3">
                  <div className="flex-1">
                    <label className="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1 block">Date début</label>
                    <input
                      type="date"
                      value={transactionStartDate}
                      onChange={(e) => setTransactionStartDate(e.target.value)}
                      className="w-full px-3 py-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div className="flex-1">
                    <label className="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1 block">Date fin</label>
                    <input
                      type="date"
                      value={transactionEndDate}
                      onChange={(e) => setTransactionEndDate(e.target.value)}
                      className="w-full px-3 py-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  {(transactionStartDate || transactionEndDate) && (
                    <button
                      onClick={() => {
                        setTransactionStartDate('');
                        setTransactionEndDate('');
                      }}
                      className="mt-5 px-3 py-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 rounded-lg text-sm font-medium transition-colors"
                    >
                      Réinitialiser
                    </button>
                  )}
                </div>
              </div>

              {/* Transactions List */}
              <div>
                <h4 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-4 flex items-center gap-2">
                  <CreditCard className="w-5 h-5 text-blue-600" />
                  Historique des Transactions
                  <span className="text-sm font-normal text-gray-500">({filteredTransactions.length})</span>
                </h4>
                <div className="space-y-3">
                  {filteredTransactions.length > 0 ? (
                    filteredTransactions.map((transaction) => (
                    <div key={transaction.id} className="bg-gray-50 dark:bg-gray-900/50 rounded-xl p-4 hover:shadow-md transition-shadow">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-3">
                          <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                            transaction.type === 'credit' ? 'bg-green-100 dark:bg-green-900/30' : 'bg-red-100 dark:bg-red-900/30'
                          }`}>
                            {transaction.type === 'credit' ? (
                              <ArrowDownRight className="w-5 h-5 text-green-600" />
                            ) : (
                              <ArrowUpRight className="w-5 h-5 text-red-600" />
                            )}
                          </div>
                          <div>
                            <p className="font-semibold text-gray-900 dark:text-gray-100">{transaction.description}</p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">{new Date(transaction.date).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}</p>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className={`text-lg font-bold ${
                            transaction.type === 'credit' ? 'text-green-600' : 'text-red-600'
                          }`}>
                            {transaction.type === 'credit' ? '+' : '-'}{formatCurrency(transaction.amount)}
                          </p>
                          <span className={`text-xs px-2 py-1 rounded-full font-medium ${getStatusColor(transaction.status)}`}>
                            {getStatusLabel(transaction.status)}
                          </span>
                        </div>
                      </div>
                    </div>
                  ))) : (
                    <div className="text-center py-8 text-gray-500 dark:text-gray-400">
                      Aucune transaction trouvée pour cette période
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="border-t border-gray-200 dark:border-gray-700 p-4 flex justify-end gap-3">
              <button onClick={() => setShowModal(false)} className="px-4 py-2 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 rounded-lg font-medium transition-colors">
                Fermer
              </button>
              <button onClick={exportAccountToImage} className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors flex items-center gap-2">
                <Download className="w-4 h-4" />
                Exporter
              </button>
            </div>
          </div>
        </div>
        );
      })()}
    </div>
  );
};

// Report Template for Export
const AccountsReport = ({ accounts, totalBalance, totalSpent }: { accounts: ClientAccount[], totalBalance: number, totalSpent: number }) => {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' }).format(amount);
  };

  return (
    <div className="bg-white text-gray-900 p-10 font-serif w-[1000px] mx-auto min-h-[1414px]">
      <div className="flex justify-between items-center border-b-2 border-gray-900 pb-6 mb-8">
        <div className="flex items-center gap-4">
          <img src={logo} alt="Logo" className="h-16 w-auto" />
          <div>
            <h1 className="text-3xl font-bold uppercase tracking-wider">Rapport des Comptes</h1>
            <p className="text-sm text-gray-500">Généré le {new Date().toLocaleDateString('fr-FR')}</p>
          </div>
        </div>
        <div className="text-right">
          <p className="font-bold">EventMaster Inc.</p>
          <p className="text-sm text-gray-600">Confidentialité: Interne</p>
        </div>
      </div>

      <div className="mb-10">
        <h2 className="text-xl font-bold mb-4 uppercase text-blue-800 border-l-4 border-blue-600 pl-3">Vue d'ensemble</h2>
        <div className="grid grid-cols-3 gap-6 mb-6">
          <div className="border border-gray-200 p-4 rounded-lg bg-gray-50">
            <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Solde Total</p>
            <p className="text-3xl font-bold text-gray-900">{formatCurrency(totalBalance)}</p>
          </div>
          <div className="border border-gray-200 p-4 rounded-lg bg-gray-50">
            <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Dépenses Totales</p>
            <p className="text-3xl font-bold text-gray-900">{formatCurrency(totalSpent)}</p>
          </div>
          <div className="border border-gray-200 p-4 rounded-lg bg-gray-50">
            <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Comptes Actifs</p>
            <p className="text-3xl font-bold text-gray-900">{accounts.length}</p>
          </div>
        </div>
      </div>

      <div className="mb-10">
        <h2 className="text-xl font-bold mb-4 uppercase text-emerald-800 border-l-4 border-emerald-600 pl-3">Détail des Comptes</h2>
        <table className="w-full border-collapse border border-gray-300 text-sm">
          <thead className="bg-gray-100">
            <tr>
              <th className="border border-gray-300 px-4 py-2 text-left uppercase text-xs">Client</th>
              <th className="border border-gray-300 px-4 py-2 text-left uppercase text-xs">Email</th>
              <th className="border border-gray-300 px-4 py-2 text-right uppercase text-xs">Solde</th>
              <th className="border border-gray-300 px-4 py-2 text-right uppercase text-xs">Dépensé</th>
              <th className="border border-gray-300 px-4 py-2 text-center uppercase text-xs">Transactions</th>
            </tr>
          </thead>
          <tbody>
            {accounts.map((account, idx) => (
              <tr key={account.id} className={idx % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                <td className="border border-gray-300 px-4 py-2 font-medium">{account.clientName}</td>
                <td className="border border-gray-300 px-4 py-2">{account.email}</td>
                <td className="border border-gray-300 px-4 py-2 text-right font-bold">{formatCurrency(account.balance)}</td>
                <td className="border border-gray-300 px-4 py-2 text-right">{formatCurrency(account.totalSpent)}</td>
                <td className="border border-gray-300 px-4 py-2 text-center">{account.totalTransactions}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mt-auto pt-8 border-t border-gray-300 flex justify-between text-xs text-gray-500">
        <p>EventMaster - Plateforme de Gestion Événementielle</p>
        <p>Ce document est confidentiel et destiné à un usage interne uniquement.</p>
      </div>
    </div>
  );
};

// Account Detail Report Template
const AccountDetailReport = ({ account, filteredTransactions, formatCurrency, getStatusLabel }: { 
  account: ClientAccount, 
  filteredTransactions: Transaction[], 
  formatCurrency: (amount: number) => string,
  getStatusLabel: (status: string) => string
}) => {
  return (
    <div className="bg-white text-gray-900 p-10 font-serif w-[1000px] mx-auto min-h-[1414px]">
      <div className="flex justify-between items-center border-b-2 border-gray-900 pb-6 mb-8">
        <div className="flex items-center gap-4">
          <img src={logo} alt="Logo" className="h-16 w-auto" />
          <div>
            <h1 className="text-3xl font-bold uppercase tracking-wider">Détails du Compte</h1>
            <p className="text-sm text-gray-500">Généré le {new Date().toLocaleDateString('fr-FR')}</p>
          </div>
        </div>
        <div className="text-right">
          <p className="font-bold">EventMaster Inc.</p>
          <p className="text-sm text-gray-600">Confidentialité: Interne</p>
        </div>
      </div>

      <div className="mb-10">
        <h2 className="text-xl font-bold mb-4 uppercase text-blue-800 border-l-4 border-blue-600 pl-3">Informations Client</h2>
        <div className="bg-gray-50 p-6 rounded-lg mb-6">
          <div className="flex items-center gap-4 mb-4">
            <img src={account.avatar} alt={account.clientName} className="w-20 h-20 rounded-full" />
            <div>
              <h3 className="text-2xl font-bold">{account.clientName}</h3>
              <p className="text-gray-600">{account.email}</p>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div className="border border-gray-200 p-4 rounded-lg bg-white">
              <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Solde Actuel</p>
              <p className="text-2xl font-bold text-blue-600">{formatCurrency(account.balance)}</p>
            </div>
            <div className="border border-gray-200 p-4 rounded-lg bg-white">
              <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Total Dépensé</p>
              <p className="text-2xl font-bold text-purple-600">{formatCurrency(account.totalSpent)}</p>
            </div>
            <div className="border border-gray-200 p-4 rounded-lg bg-white">
              <p className="text-xs uppercase tracking-widest text-gray-500 mb-1">Transactions</p>
              <p className="text-2xl font-bold text-emerald-600">{account.totalTransactions}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="mb-10">
        <h2 className="text-xl font-bold mb-4 uppercase text-emerald-800 border-l-4 border-emerald-600 pl-3">Historique des Transactions ({filteredTransactions.length})</h2>
        <table className="w-full border-collapse border border-gray-300 text-sm">
          <thead className="bg-gray-100">
            <tr>
              <th className="border border-gray-300 px-4 py-2 text-left uppercase text-xs">Date</th>
              <th className="border border-gray-300 px-4 py-2 text-left uppercase text-xs">Description</th>
              <th className="border border-gray-300 px-4 py-2 text-center uppercase text-xs">Type</th>
              <th className="border border-gray-300 px-4 py-2 text-right uppercase text-xs">Montant</th>
              <th className="border border-gray-300 px-4 py-2 text-center uppercase text-xs">Statut</th>
            </tr>
          </thead>
          <tbody>
            {filteredTransactions.map((transaction, idx) => (
              <tr key={transaction.id} className={idx % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                <td className="border border-gray-300 px-4 py-2">{new Date(transaction.date).toLocaleDateString('fr-FR')}</td>
                <td className="border border-gray-300 px-4 py-2">{transaction.description}</td>
                <td className="border border-gray-300 px-4 py-2 text-center uppercase text-xs">{transaction.type === 'credit' ? 'Crédit' : 'Débit'}</td>
                <td className={`border border-gray-300 px-4 py-2 text-right font-bold ${transaction.type === 'credit' ? 'text-green-600' : 'text-red-600'}`}>
                  {transaction.type === 'credit' ? '+' : '-'}{formatCurrency(transaction.amount)}
                </td>
                <td className="border border-gray-300 px-4 py-2 text-center text-xs uppercase">{getStatusLabel(transaction.status)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mt-auto pt-8 border-t border-gray-300 flex justify-between text-xs text-gray-500">
        <p>EventMaster - Plateforme de Gestion Événementielle</p>
        <p>Ce document est confidentiel et destiné à un usage interne uniquement.</p>
      </div>
    </div>
  );
};
