import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:flutter/material.dart';
import 'package:buscando_minas/assets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CellView extends StatelessWidget {
  final Cell cell;

  // ignore: prefer_const_constructors_in_immutables
  CellView({super.key, required this.cell});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<GameBloc>().add(TapCell(cell.index));
      },
      onLongPress: () {
        context.read<GameBloc>().add(ToggleFlag(cell.index));
      },
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_imageForCell(cell)),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  String _imageForCell(Cell cell) {
    if (cell is CellClosed) {
      if (cell.flagged) {
        return Assets.cellFlagged;
      } else {
        return Assets.cellClosed;
      }
    } else {
      if (cell.content == CellContent.bomb) {
        return Assets.cellBomb;
      }
      return Assets.openedCells[cell.content.index];
    }
  }
}
