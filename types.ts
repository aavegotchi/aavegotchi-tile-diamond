import { BigNumberish } from "@ethersproject/bignumber";

export interface TileType {
  tileType: BigNumberish;
  width: BigNumberish;
  height: BigNumberish;
  alchemicaType: BigNumberish;
  alchemicaCost: BigNumberish[];
  craftTime: BigNumberish;
}
