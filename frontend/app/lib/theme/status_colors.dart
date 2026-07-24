import 'package:flutter/material.dart';

/// Verde fixo (não vem do ColorScheme, que não modela "sucesso" como
/// conceito) — escolhido para manter contraste legível tanto em fundo claro
/// quanto escuro, ao contrário de Colors.green padrão do Material
/// (calibrado para fundo claro).
const successColor = Color(0xFF4CAF50);

/// Laranja fixo, mesmo motivo de [successColor] — usado para estados de
/// aviso/parcial.
const warningColor = Color(0xFFFFA726);
