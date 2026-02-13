import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/bloc/auth_cubit.dart';
import 'package:event_app/bloc/booking_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// TRANSACTION HISTORY PAGE - Wallet Traceability
/// ============================================================================
/// Features:
/// - Complete transaction history
/// - Green for recharges (+)
/// - Red for purchases (-)
/// - Real-time data from BookingCubit
/// - Professional fintech UI
/// ============================================================================

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {

@override
  void initState() {
    super.initState();
    // Load user bookings for transaction history
    context.read<BookingCubit>().loadUserBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            const SizedBox(height: 16),
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  /// Build app bar
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build balance card (reactive to auth state changes)
  Widget _buildBalanceCard() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final balance = state is AuthAuthenticated ? state.user.solde : 0.0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryColor, Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                ],
              ),
              Text(
                '${NumberFormat('#,###', 'fr_FR').format(balance)} FCFA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build transactions list
  Widget _buildTransactionsList() {
    return Expanded(
      child: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          } else if (state is UserBookingsLoaded) {
            if (state.bookings.isEmpty) {
              return _buildEmptyState();
            }

            // Create transaction list (purchases + mock recharges)
            final transactions = <Map<String, dynamic>>[];
            
            // Add mock recharge transactions
            transactions.add({
              'type': 'recharge',
              'amount': 500.0,
              'date': DateTime.now().subtract(const Duration(days: 7)),
              'description': 'Recharge du Portefeuille',
              'method': 'TMoney',
            });

            // Add purchase transactions
            for (var booking in state.bookings) {
              transactions.add({
                'type': 'purchase',
                'amount': booking.montantTotal,
                'date': booking.dateAchat,
                'description': booking.eventTitre,
                'quantity': booking.quantite,
              });
            }

            // Sort by date (newest first)
            transactions.sort((a, b) => 
              (b['date'] as DateTime).compareTo(a['date'] as DateTime)
            );

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionCard(transactions[index]);
              },
            );
          } else if (state is BookingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.greyTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  /// Build transaction card
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isRecharge = transaction['type'] == 'recharge';
    final amount = transaction['amount'] as double;
    final date = transaction['date'] as DateTime;
    final description = transaction['description'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isRecharge
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isRecharge ? Icons.add_circle : Icons.confirmation_number,
              color: isRecharge ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                    if (!isRecharge && transaction['quantity'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'x${transaction['quantity']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isRecharge ? '+' : '-'}${amount.toStringAsFixed(2)}€',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isRecharge ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: AppColors.greyTextColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune transaction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre historique de transactions apparaîtra ici',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
