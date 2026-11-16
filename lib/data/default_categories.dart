import 'models/category_model.dart';
import 'models/tx_type.dart';
import 'models/wallet_model.dart';

const defaultCategories = <CategoryModel>[
  CategoryModel(
    name: 'Makanan & Minuman',
    type: TxType.expense,
    icon: 'food',
    color: 0xFFFB8C00,
  ),
  CategoryModel(
    name: 'Transportasi',
    type: TxType.expense,
    icon: 'transport',
    color: 0xFF1E88E5,
  ),
  CategoryModel(
    name: 'Belanja',
    type: TxType.expense,
    icon: 'shopping',
    color: 0xFFD81B60,
  ),
  CategoryModel(
    name: 'Tagihan',
    type: TxType.expense,
    icon: 'bill',
    color: 0xFFE53935,
  ),
  CategoryModel(
    name: 'Rumah Tangga',
    type: TxType.expense,
    icon: 'home',
    color: 0xFF6D4C41,
  ),
  CategoryModel(
    name: 'Kesehatan',
    type: TxType.expense,
    icon: 'health',
    color: 0xFF43A047,
  ),
  CategoryModel(
    name: 'Pendidikan',
    type: TxType.expense,
    icon: 'education',
    color: 0xFF3949AB,
  ),
  CategoryModel(
    name: 'Hiburan',
    type: TxType.expense,
    icon: 'entertainment',
    color: 0xFF8E24AA,
  ),
  CategoryModel(
    name: 'Lainnya',
    type: TxType.expense,
    icon: 'other',
    color: 0xFF757575,
  ),
  CategoryModel(
    name: 'Gaji',
    type: TxType.income,
    icon: 'salary',
    color: 0xFF43A047,
  ),
  CategoryModel(
    name: 'Bonus',
    type: TxType.income,
    icon: 'bonus',
    color: 0xFFF9A825,
  ),
  CategoryModel(
    name: 'Investasi',
    type: TxType.income,
    icon: 'investment',
    color: 0xFF00897B,
  ),
  CategoryModel(
    name: 'Usaha',
    type: TxType.income,
    icon: 'business',
    color: 0xFF1E88E5,
  ),
  CategoryModel(
    name: 'Hadiah',
    type: TxType.income,
    icon: 'gift',
    color: 0xFFD81B60,
  ),
  CategoryModel(
    name: 'Lainnya',
    type: TxType.income,
    icon: 'other',
    color: 0xFF757575,
  ),
];

const defaultWallets = <WalletModel>[
  WalletModel(name: 'Tunai', type: WalletType.cash, color: 0xFF43A047),
  WalletModel(name: 'Rekening Bank', type: WalletType.bank, color: 0xFF1E88E5),
];
