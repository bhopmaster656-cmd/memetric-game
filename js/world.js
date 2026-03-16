/**
 * World / terrain generation.
 * Generates a height-map, then classifies each tile into a terrain type.
 * Also places initial forest patches and water features.
 */

class World {
    constructor(width, height, tileSize) {
        this.width    = width;
        this.height   = height;
        this.tileSize = tileSize;
        this.cols     = Math.ceil(width  / tileSize);
        this.rows     = Math.ceil(height / tileSize);
        this.tiles    = null;
        this.season   = 'summer';
    }

    generate() {
        const { cols, rows } = this;
        const scale  = 0.018;
        const scale2 = 0.06;

        this.tiles = new Uint8Array(cols * rows);

        for (let row = 0; row < rows; row++) {
            for (let col = 0; col < cols; col++) {
                const nx = col * scale;
                const ny = row * scale;

                // Island mask – fade to water at borders
                const cx = col / cols - 0.5;
                const cy = row / rows - 0.5;
                const islandMask = 1 - Math.sqrt(cx * cx * 3 + cy * cy * 3);

                const h = fbm(nx, ny, 6, 0.55, 2.1) * islandMask
                        + fbm(nx + 100, ny + 100, 2, 0.5, 2.0) * 0.15;

                let type;
                if (h < 0.05)       type = TERRAIN.DEEP_WATER;
                else if (h < 0.18)  type = TERRAIN.WATER;
                else if (h < 0.25)  type = TERRAIN.SAND;
                else if (h < 0.65)  {
                    // Some grass tiles become forest based on secondary noise
                    const fn = fbm(nx * 3 + 50, ny * 3 + 50, 3, 0.5, 2.0);
                    type = fn > 0.62 ? TERRAIN.FOREST : TERRAIN.GRASS;
                }
                else if (h < 0.80)  type = TERRAIN.HILL;
                else                type = TERRAIN.MOUNTAIN;

                this.tiles[row * cols + col] = type;
            }
        }

        // Find a good starting position — centre-ish flat grass area
        this.startTile = this._findStartTile();
    }

    _findStartTile() {
        const { cols, rows } = this;
        // Search near centre
        const cx = Math.floor(cols / 2);
        const cy = Math.floor(rows / 2);
        for (let r = 0; r < 30; r++) {
            for (let c = -r; c <= r; c++) {
                for (let dr = -r; dr <= r; dr++) {
                    const col = cx + c, row = cy + dr;
                    if (col >= 0 && col < cols && row >= 0 && row < rows) {
                        if (this.getTile(col, row) === TERRAIN.GRASS) {
                            return { col, row };
                        }
                    }
                }
            }
        }
        return { col: cx, row: cy };
    }

    getTile(col, row) {
        if (col < 0 || col >= this.cols || row < 0 || row >= this.rows)
            return TERRAIN.DEEP_WATER;
        return this.tiles[row * this.cols + col];
    }

    /** Convert world pixel coords to tile coords */
    pixelToTile(px, py) {
        return {
            col: Math.floor(px / this.tileSize),
            row: Math.floor(py / this.tileSize),
        };
    }

    /** Tile coords to world pixel (top-left corner) */
    tileToPixel(col, row) {
        return { x: col * this.tileSize, y: row * this.tileSize };
    }

    /** Return the terrain colour for the current season */
    tileColor(type) {
        const sc = SEASON_COLORS[this.season];
        if (type === TERRAIN.GRASS)  return sc.grass;
        if (type === TERRAIN.FOREST) return sc.tree;
        return TERRAIN_COLORS[type];
    }

    /** Is world position (px,py) on passable (non-water/mountain) terrain? */
    isPassable(px, py) {
        const { col, row } = this.pixelToTile(px, py);
        const t = this.getTile(col, row);
        return t !== TERRAIN.DEEP_WATER && t !== TERRAIN.WATER && t !== TERRAIN.MOUNTAIN;
    }

    /** Is a rectangle of world coords entirely on buildable terrain? */
    isBuildable(x, y, w, h) {
        const margin = CONFIG.buildableCheckMargin;
        const tl = this.pixelToTile(x + margin, y + margin);
        const tr = this.pixelToTile(x + w - margin, y + margin);
        const bl = this.pixelToTile(x + margin, y + h - margin);
        const br = this.pixelToTile(x + w - margin, y + h - margin);
        for (let r = tl.row; r <= bl.row; r++) {
            for (let c = tl.col; c <= br.col; c++) {
                const t = this.getTile(c, r);
                if (t === TERRAIN.DEEP_WATER || t === TERRAIN.WATER || t === TERRAIN.MOUNTAIN)
                    return false;
            }
        }
        return true;
    }

    setSeason(season) { this.season = season; }
}
