import 'package:flutter/material.dart';

// ===================== TEMA: iOS LIGHT =====================
//
// Mesmos NOMES de constante de antes (kPrimaryColor, kbackgroundColor etc.)
// — só os valores mudaram, de dark (WhatsApp/Signal) pra light (iOS). Como
// as ~48 telas do app importam e usam essas constantes diretamente (em vez
// de Theme.of(context)), trocar os valores aqui já re-pinta o app inteiro
// sem precisar editar tela por tela.

/// Acento do app. Era o verde do WhatsApp/Signal (#00A783); agora é o azul
/// de sistema do iOS (#007AFF) — usado em FAB, tabs, ícones de destaque e
/// (via ksenderMessageBubbleColor) na bolha de mensagem enviada.
const kPrimaryColor = Color(0xFF007AFF);

/// Fundo principal das telas — cinza gelo padrão iOS (systemGroupedBackground).
const kbackgroundColor = Color(0xFFF2F2F7);

/// Texto principal — quase-preto (iOS label), não preto puro.
const kTextColor = Color(0xFF1C1C1E);

/// Texto secundário/subtítulos — cinza iOS (secondaryLabel).
const kTextDarkColor = Color(0xFF8E8E93);

/// Ícones no mesmo tom do texto principal (ícone escuro sobre fundo claro).
const kIconColor = Color(0xFF1C1C1E);

/// Fundo da AppBar — branco, superfície limpa estilo iOS nav bar.
const kAppBarColor = Color(0xFFFFFFFF);

/// Bolha de mensagem RECEBIDA — cinza claro estilo iMessage.
const kmessageBubbleColor = Color(0xFFE9E9EB);

/// Bolha de mensagem ENVIADA — azul iOS estilo iMessage.
const ksenderMessageBubbleColor = Color(0xFF007AFF);

const kBlueTickColor = Color(0xFF00AEFF);

/// Tique/tick não lido — mesmo cinza secundário do resto do tema.
const kGreyTickColor = Color(0xFF8E8E93);

/// Cor de tab ativa — mesma do acento.
const kTabColor = Color(0xFF007AFF);

/// Fundo de campos de busca/input — cinza claro (iOS systemGray5/6).
const ksearchBarColor = Color(0xFFE5E5EA);

/// Linhas divisórias — cinza claro padrão de separador iOS.
const kDividerColor = Color(0xFFC6C6C8);

/// Fundo da barra de digitar mensagem / campo de busca (mesmo tom do
/// ksearchBarColor, nome histórico mantido).
const kchatBarMessage = Color(0xFFE5E5EA);

/// Fundo da barra de input do chat (branco, contraste com o cinza do
/// restante da tela).
const kmobileChatBoxColor = Color(0xFFFFFFFF);
