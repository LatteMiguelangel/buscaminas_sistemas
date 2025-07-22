// cell_view.dart
import 'package:flutter/material.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/assets.dart';

class CellView extends StatelessWidget {
  final Cell cell;
  final bool isClientFlag;
  const CellView({super.key, required this.cell, required this.isClientFlag});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_imageForCell(cell)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _imageForCell(Cell cell) {
    if (cell is CellClosed) {
      // Si está cerrada y marcada…
      if (cell.flagged) {
        return isClientFlag
            ? Assets
                .cellFlagged2 // bandera del cliente
            : Assets.cellFlagged; // bandera del host
      }
      // Cerrada y sin marcar
      return Assets.cellClosed;
    } else {
      // Celda abierta
      if (cell.content == CellContent.bomb) {
        return Assets.cellBomb;
      }
      return Assets.openedCells[cell.content.index];
    }
  }
}
