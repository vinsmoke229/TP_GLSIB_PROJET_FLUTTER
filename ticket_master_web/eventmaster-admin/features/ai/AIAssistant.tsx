import React, { useState, useRef, useEffect } from 'react';
import { Send, Bot, User, Loader2, MessageSquare, TrendingUp, RefreshCw, AlertCircle, Sparkles } from 'lucide-react';
import { AIMessage, AIPrediction, Event, SalesData } from '../../types';
import { chatWithAI, generateSalesAnalysis } from '../../services/geminiService';

interface AIAssistantProps {
  events: Event[];
  salesData: SalesData[];
}

type AITab = 'chat' | 'forecasts';

export const AIAssistant: React.FC<AIAssistantProps> = ({ events, salesData }) => {
  const [activeTab, setActiveTab] = useState<AITab>('chat');

  // Chat state
  const [messages, setMessages] = useState<AIMessage[]>([
    {
      id: '1',
      role: 'assistant',
      content: 'Bonjour ! Je suis votre assistant IA pour EventMaster. Comment puis-je vous aider avec vos événements et analyses ?',
      timestamp: new Date()
    }
  ]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoadingChat, setIsLoadingChat] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Forecasts state
  const [prediction, setPrediction] = useState<AIPrediction | null>(null);
  const [isLoadingForecasts, setIsLoadingForecasts] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    if (activeTab === 'forecasts' && !prediction && !isLoadingForecasts) {
      loadPrediction();
    }
  }, [activeTab]);

  const loadPrediction = async () => {
    setIsLoadingForecasts(true);
    setError(null);
    try {
      const result = await generateSalesAnalysis(events, salesData);
      setPrediction(result);
    } catch (err) {
      setError('Impossible de générer les prévisions pour le moment.');
    } finally {
      setIsLoadingForecasts(false);
    }
  };

  const handleSendMessage = async () => {
    if (!inputMessage.trim() || isLoadingChat) return;

    const userMessage: AIMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: inputMessage.trim(),
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputMessage('');
    setIsLoadingChat(true);

    try {
      const response = await chatWithAI([...messages, userMessage], { events, salesData });

      const aiMessage: AIMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response,
        timestamp: new Date()
      };

      setMessages(prev => [...prev, aiMessage]);
    } catch (error) {
      const errorMessage: AIMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: 'Désolé, une erreur s\'est produite. Veuillez réessayer.',
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoadingChat(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const getConfidenceColor = (score: number) => {
    if (score >= 80) return 'text-green-600';
    if (score >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getConfidenceBg = (score: number) => {
    if (score >= 80) return 'bg-green-100 dark:bg-green-900/30';
    if (score >= 60) return 'bg-yellow-100 dark:bg-yellow-900/30';
    return 'bg-red-100 dark:bg-red-900/30';
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
              <Bot className="w-6 h-6 text-white" />
            </div>
            Assistant IA
          </h1>
          <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
            Discutez avec l'IA et obtenez des prévisions intelligentes
          </p>
        </div>
        <div className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-emerald-50 to-teal-50 dark:from-emerald-900/20 dark:to-teal-900/20 rounded-xl border border-emerald-200 dark:border-emerald-800">
          <Sparkles className="w-4 h-4 text-emerald-600" />
          <span className="text-sm font-medium text-emerald-700 dark:text-emerald-400">Propulsé par Gemini AI</span>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 bg-white dark:bg-gray-800 p-1 rounded-xl border border-gray-200 dark:border-gray-700 w-fit">
        <button
          onClick={() => setActiveTab('chat')}
          className={`flex items-center gap-2 px-6 py-3 rounded-lg text-sm font-medium transition-all ${
            activeTab === 'chat'
              ? 'bg-emerald-600 text-white shadow-lg'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'
          }`}
        >
          <MessageSquare className="w-4 h-4" />
          Discussion
        </button>
        <button
          onClick={() => setActiveTab('forecasts')}
          className={`flex items-center gap-2 px-6 py-3 rounded-lg text-sm font-medium transition-all ${
            activeTab === 'forecasts'
              ? 'bg-emerald-600 text-white shadow-lg'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'
          }`}
        >
          <TrendingUp className="w-4 h-4" />
          Prévisions
        </button>
      </div>

      {/* Content */}
      {activeTab === 'chat' && (
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm flex flex-col h-[calc(100vh-280px)]">
          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-6 space-y-4">
            {messages.map((message) => (
              <div
                key={message.id}
                className={`flex gap-3 ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                {message.role === 'assistant' && (
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center flex-shrink-0">
                    <Bot className="w-5 h-5 text-white" />
                  </div>
                )}
                <div
                  className={`max-w-[70%] p-4 rounded-xl ${
                    message.role === 'user'
                      ? 'bg-emerald-600 text-white'
                      : 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-100'
                  }`}
                >
                  <p className="text-sm whitespace-pre-wrap leading-relaxed">{message.content}</p>
                  <p className="text-xs opacity-70 mt-2">
                    {message.timestamp.toLocaleTimeString('fr-FR', {
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </p>
                </div>
                {message.role === 'user' && (
                  <div className="w-10 h-10 rounded-full bg-emerald-600 flex items-center justify-center flex-shrink-0">
                    <User className="w-5 h-5 text-white" />
                  </div>
                )}
              </div>
            ))}
            {isLoadingChat && (
              <div className="flex gap-3 justify-start">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center flex-shrink-0">
                  <Bot className="w-5 h-5 text-white" />
                </div>
                <div className="bg-gray-100 dark:bg-gray-700 p-4 rounded-xl">
                  <Loader2 className="w-5 h-5 animate-spin text-emerald-600" />
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          {/* Input */}
          <div className="p-6 border-t border-gray-200 dark:border-gray-700">
            <div className="flex gap-3">
              <input
                type="text"
                value={inputMessage}
                onChange={(e) => setInputMessage(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Tapez votre message..."
                className="flex-1 px-4 py-3 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 outline-none"
                disabled={isLoadingChat}
              />
              <button
                onClick={handleSendMessage}
                disabled={!inputMessage.trim() || isLoadingChat}
                className="px-6 py-3 bg-emerald-600 hover:bg-emerald-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white rounded-xl transition-colors flex items-center gap-2 font-medium"
              >
                <Send className="w-4 h-4" />
                Envoyer
              </button>
            </div>
          </div>
        </div>
      )}

      {activeTab === 'forecasts' && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100">Prévisions IA</h2>
              <p className="text-gray-600 dark:text-gray-400 mt-1 text-sm">
                Analyses et prédictions basées sur vos données d'événements
              </p>
            </div>
            <button
              onClick={loadPrediction}
              disabled={isLoadingForecasts}
              className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:bg-gray-400 text-white rounded-xl transition-colors text-sm font-medium"
            >
              <RefreshCw className={`w-4 h-4 ${isLoadingForecasts ? 'animate-spin' : ''}`} />
              Actualiser
            </button>
          </div>

          {error && (
            <div className="bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-800 rounded-xl p-4">
              <div className="flex items-center gap-2">
                <AlertCircle className="w-5 h-5 text-red-600" />
                <p className="text-red-800 dark:text-red-200">{error}</p>
              </div>
            </div>
          )}

          {isLoadingForecasts && !prediction && (
            <div className="flex items-center justify-center py-12">
              <div className="flex items-center gap-3 text-gray-600 dark:text-gray-400">
                <RefreshCw className="w-6 h-6 animate-spin" />
                <span>Génération des prévisions...</span>
              </div>
            </div>
          )}

          {prediction && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Summary Card */}
              <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                    <TrendingUp className="w-5 h-5 text-blue-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    Résumé de Performance
                  </h3>
                </div>
                <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                  {prediction.summary}
                </p>
              </div>

              {/* Suggested Action Card */}
              <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 rounded-xl bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
                    <Sparkles className="w-5 h-5 text-emerald-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    Action Suggérée
                  </h3>
                </div>
                <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                  {prediction.suggestedAction}
                </p>
              </div>

              {/* Projected Revenue Card */}
              <div className="bg-gradient-to-br from-purple-500 to-fuchsia-600 rounded-xl p-6 text-white shadow-lg">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                    <TrendingUp className="w-5 h-5 text-white" />
                  </div>
                  <h3 className="text-lg font-semibold">
                    Revenu Projeté (Mois Prochain)
                  </h3>
                </div>
                <div className="text-4xl font-bold mb-2">
                  {formatCurrency(prediction.projectedRevenue)}
                </div>
                <p className="text-purple-100 text-sm">
                  Basé sur les tendances actuelles
                </p>
              </div>

              {/* Confidence Score Card */}
              <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 shadow-sm">
                <div className="flex items-center gap-3 mb-4">
                  <div className={`w-10 h-10 rounded-xl ${getConfidenceBg(prediction.confidenceScore)} flex items-center justify-center`}>
                    <TrendingUp className={`w-5 h-5 ${getConfidenceColor(prediction.confidenceScore)}`} />
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    Score de Confiance
                  </h3>
                </div>
                <div className={`text-4xl font-bold mb-3 ${getConfidenceColor(prediction.confidenceScore)}`}>
                  {prediction.confidenceScore}%
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-600 rounded-full h-3">
                  <div
                    className={`h-3 rounded-full transition-all duration-300 ${
                      prediction.confidenceScore >= 80 ? 'bg-green-500' :
                      prediction.confidenceScore >= 60 ? 'bg-yellow-500' : 'bg-red-500'
                    }`}
                    style={{ width: `${prediction.confidenceScore}%` }}
                  ></div>
                </div>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-3">
                  Fiabilité de la prédiction
                </p>
              </div>

              {/* Additional Insights */}
              <div className="lg:col-span-2 bg-gradient-to-r from-emerald-50 to-blue-50 dark:from-emerald-900/20 dark:to-blue-900/20 rounded-xl border border-emerald-200 dark:border-emerald-800 p-6">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
                  Insights Supplémentaires
                </h3>
                <div className="grid grid-cols-3 gap-6">
                  <div className="text-center">
                    <div className="text-3xl font-bold text-emerald-600">
                      {events.filter(e => e.status === 'published').length}
                    </div>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">Événements Actifs</p>
                  </div>
                  <div className="text-center">
                    <div className="text-3xl font-bold text-blue-600">
                      {events.reduce((acc, e) => acc + e.ticketTypes.reduce((sum, t) => sum + t.quantitySold, 0), 0)}
                    </div>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">Billets Vendus</p>
                  </div>
                  <div className="text-center">
                    <div className="text-3xl font-bold text-purple-600">
                      {formatCurrency(salesData.reduce((acc, s) => acc + s.revenue, 0))}
                    </div>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">Revenus Totaux</p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
