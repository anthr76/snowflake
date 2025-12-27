{
  zramSwap = {
    enable = true;
    # 50% provides good headroom for memory-hungry games
    # zram compresses ~2-3x, so 50% RAM = 100-150% effective swap
    memoryPercent = 50;
  };
}
