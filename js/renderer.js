/**
 * Canvas 2D renderer – world, buildings, roads, residents.
 * Buildings drawn as proper medieval structures (walls, roof, windows, doors).
 * Residents drawn as human silhouettes, not circles.
 */

class Renderer {
    constructor(canvas, world) {
        this.canvas  = canvas;
        this.ctx     = canvas.getContext('2d');
        this.world   = world;

        this.camX    = 0;
        this.camY    = 0;
        this.zoom    = 1;
        this.minZoom = 0.3;
        this.maxZoom = 3.0;

        this._terrainCache = null;
        this._terrainDirty = true;

        this.resize();
    }

    resize() {
        this.canvas.width  = window.innerWidth;
        this.canvas.height = window.innerHeight;
        this._terrainDirty = true;
    }

    /* ── Camera ─────────────────────────────────────────────────────────── */

    screenToWorld(sx, sy) {
        return {
            x: (sx - this.canvas.width  / 2) / this.zoom + this.camX,
            y: (sy - this.canvas.height / 2) / this.zoom + this.camY,
        };
    }

    worldToScreen(wx, wy) {
        return {
            x: (wx - this.camX) * this.zoom + this.canvas.width  / 2,
            y: (wy - this.camY) * this.zoom + this.canvas.height / 2,
        };
    }

    centerOn(wx, wy) { this.camX = wx; this.camY = wy; }

    pan(dx, dy) {
        this.camX -= dx / this.zoom;
        this.camY -= dy / this.zoom;
        this._clampCamera();
    }

    zoomAt(sx, sy, factor) {
        const wBefore = this.screenToWorld(sx, sy);
        this.zoom     = clamp(this.zoom * factor, this.minZoom, this.maxZoom);
        const wAfter  = this.screenToWorld(sx, sy);
        this.camX    += wBefore.x - wAfter.x;
        this.camY    += wBefore.y - wAfter.y;
        this._clampCamera();
        this._terrainDirty = true;
    }

    _clampCamera() {
        const hw = this.canvas.width  / 2 / this.zoom;
        const hh = this.canvas.height / 2 / this.zoom;
        this.camX = clamp(this.camX, hw, this.world.width  - hw);
        this.camY = clamp(this.camY, hh, this.world.height - hh);
    }

    /* ── Terrain ─────────────────────────────────────────────────────────── */

    _buildTerrainCache() {
        const { cols, rows, tileSize } = this.world;
        const off = document.createElement('canvas');
        off.width  = cols * tileSize;
        off.height = rows * tileSize;
        const ctx = off.getContext('2d');
        const ts  = tileSize;

        for (let row = 0; row < rows; row++) {
            for (let col = 0; col < cols; col++) {
                const type = this.world.getTile(col, row);
                ctx.fillStyle = this.world.tileColor(type);
                ctx.fillRect(col * ts, row * ts, ts, ts);

                if (type === TERRAIN.FOREST) {
                    const cx = col * ts + ts * 0.5, cy = row * ts + ts * 0.5;
                    ctx.fillStyle = '#1a4a1a';
                    ctx.beginPath();
                    ctx.moveTo(cx, cy - ts * 0.42);
                    ctx.lineTo(cx + ts * 0.32, cy + ts * 0.25);
                    ctx.lineTo(cx - ts * 0.32, cy + ts * 0.25);
                    ctx.closePath();
                    ctx.fill();
                    ctx.fillStyle = '#7a5030';
                    ctx.fillRect(cx - ts * 0.07, cy + ts * 0.22, ts * 0.14, ts * 0.2);
                }
                if (type === TERRAIN.MOUNTAIN) {
                    const cx = col * ts + ts * 0.5, cy = row * ts + ts * 0.5;
                    ctx.fillStyle = '#aaaaaa';
                    ctx.beginPath();
                    ctx.moveTo(cx, cy - ts * 0.44);
                    ctx.lineTo(cx + ts * 0.44, cy + ts * 0.3);
                    ctx.lineTo(cx - ts * 0.44, cy + ts * 0.3);
                    ctx.closePath();
                    ctx.fill();
                    ctx.fillStyle = '#eeeeee';
                    ctx.beginPath();
                    ctx.moveTo(cx, cy - ts * 0.44);
                    ctx.lineTo(cx + ts * 0.14, cy - ts * 0.2);
                    ctx.lineTo(cx - ts * 0.14, cy - ts * 0.2);
                    ctx.closePath();
                    ctx.fill();
                }
                if (type === TERRAIN.WATER || type === TERRAIN.DEEP_WATER) {
                    ctx.fillStyle = 'rgba(255,255,255,0.07)';
                    ctx.fillRect(col * ts, row * ts, ts, ts / 3);
                }
                ctx.strokeStyle = 'rgba(0,0,0,0.04)';
                ctx.lineWidth = 0.5;
                ctx.strokeRect(col * ts, row * ts, ts, ts);
            }
        }
        this._terrainCache = off;
        this._terrainDirty = false;
    }

    _drawTerrain() {
        if (this._terrainDirty) this._buildTerrainCache();
        const { x: sx, y: sy } = this.worldToScreen(0, 0);
        this.ctx.drawImage(
            this._terrainCache,
            sx, sy,
            this.world.cols * this.world.tileSize * this.zoom,
            this.world.rows * this.world.tileSize * this.zoom,
        );
    }

    /* ── Roads ───────────────────────────────────────────────────────────── */

    _drawRoads(roads) {
        const ctx = this.ctx;
        ctx.save();
        ctx.strokeStyle = 'rgba(0,0,0,0.22)';
        ctx.lineWidth   = Math.max(3, 7 * this.zoom);
        ctx.lineCap = 'round'; ctx.lineJoin = 'round';
        for (const road of roads) {
            if (road.points.length < 2) continue;
            const p0 = this.worldToScreen(road.points[0].x, road.points[0].y);
            ctx.beginPath(); ctx.moveTo(p0.x, p0.y + 2);
            for (let i = 1; i < road.points.length; i++) {
                const p = this.worldToScreen(road.points[i].x, road.points[i].y);
                ctx.lineTo(p.x, p.y + 2);
            }
            ctx.stroke();
        }
        ctx.strokeStyle = '#c8a870';
        ctx.lineWidth   = Math.max(2, 5 * this.zoom);
        for (const road of roads) {
            if (road.points.length < 2) continue;
            const p0 = this.worldToScreen(road.points[0].x, road.points[0].y);
            ctx.beginPath(); ctx.moveTo(p0.x, p0.y);
            for (let i = 1; i < road.points.length; i++) {
                const p = this.worldToScreen(road.points[i].x, road.points[i].y);
                ctx.lineTo(p.x, p.y);
            }
            ctx.stroke();
        }
        ctx.restore();
    }

    /* ── Buildings ───────────────────────────────────────────────────────── */

    _drawBuildings(buildings, selectedId, time) {
        const ctx    = this.ctx;
        const sorted = buildings.slice().sort((a, b) => (a.y + a.h) - (b.y + b.h));

        for (const b of sorted) {
            const { x: sx, y: sy } = this.worldToScreen(b.x, b.y);
            const sw = b.w * this.zoom;
            const sh = b.h * this.zoom;
            if (sx + sw < -20 || sx > this.canvas.width + 20 ||
                sy + sh < -20 || sy > this.canvas.height + 20) continue;

            ctx.save();
            if (!b.constructed) {
                this._drawUnderConstruction(ctx, sx, sy, sw, sh, b);
                ctx.restore();
                continue;
            }

            // Drop shadow
            ctx.fillStyle = 'rgba(0,0,0,0.22)';
            ctx.fillRect(sx + sw * 0.07, sy + sh * 0.09, sw, sh);

            this._drawBuildingShape(ctx, b, sx, sy, sw, sh, time);

            // Selection ring
            if (b.id === selectedId) {
                ctx.strokeStyle = '#ffee44';
                ctx.lineWidth   = 3;
                ctx.shadowColor = '#ffee44';
                ctx.shadowBlur  = 12;
                ctx.strokeRect(sx - 2, sy - 2, sw + 4, sh + 4);
                ctx.shadowBlur  = 0;
            }

            // Name label
            if (this.zoom > 0.85) {
                const fs = Math.max(8, Math.min(10 * this.zoom, 13));
                ctx.font         = `bold ${fs}px sans-serif`;
                ctx.textAlign    = 'center';
                ctx.textBaseline = 'bottom';
                ctx.strokeStyle  = 'rgba(0,0,0,0.75)';
                ctx.lineWidth    = 3;
                ctx.fillStyle    = '#fff';
                ctx.strokeText(b.def.name, sx + sw / 2, sy - 3);
                ctx.fillText  (b.def.name, sx + sw / 2, sy - 3);
            }

            // Worker badge
            if (b.def.maxWorkers && this.zoom > 0.5) {
                const full = b.workerCount >= b.maxWorkers;
                const br   = Math.max(5, 7 * this.zoom);
                const bx   = sx + sw - br - 2;
                const by   = sy + br + 2;
                ctx.fillStyle   = full ? '#3aaa33' : '#e87820';
                ctx.strokeStyle = '#111';
                ctx.lineWidth   = 1;
                ctx.beginPath();
                ctx.arc(bx, by, br, 0, Math.PI * 2);
                ctx.fill(); ctx.stroke();
                ctx.font         = `bold ${Math.max(6, 7 * this.zoom)}px sans-serif`;
                ctx.fillStyle    = '#fff';
                ctx.textAlign    = 'center';
                ctx.textBaseline = 'middle';
                ctx.fillText(`${b.workerCount}/${b.maxWorkers}`, bx, by);
            }

            ctx.restore();
        }
    }

    _drawBuildingShape(ctx, b, sx, sy, sw, sh, time) {
        switch (b.type) {
            case 'cottage':    this._bldCottage(ctx, sx, sy, sw, sh, 0);   break;
            case 'house':      this._bldCottage(ctx, sx, sy, sw, sh, 1);   break;
            case 'mansion':    this._bldMansion(ctx, sx, sy, sw, sh);      break;
            case 'farm':       this._bldFarm(ctx, sx, sy, sw, sh);         break;
            case 'hunting':    this._bldHunting(ctx, sx, sy, sw, sh);      break;
            case 'fishery':    this._bldFishery(ctx, sx, sy, sw, sh);      break;
            case 'lumbermill': this._bldLumbermill(ctx, sx, sy, sw, sh);   break;
            case 'quarry':     this._bldQuarry(ctx, sx, sy, sw, sh);       break;
            case 'smithy':     this._bldSmithy(ctx, sx, sy, sw, sh, time); break;
            case 'mine':       this._bldMine(ctx, sx, sy, sw, sh);         break;
            case 'market':     this._bldMarket(ctx, sx, sy, sw, sh);       break;
            case 'tavern':     this._bldTavern(ctx, sx, sy, sw, sh);       break;
            case 'townhall':   this._bldTownhall(ctx, sx, sy, sw, sh, time); break;
            case 'church':     this._bldChurch(ctx, sx, sy, sw, sh);       break;
            case 'school':     this._bldSchool(ctx, sx, sy, sw, sh);       break;
            case 'castle':     this._bldCastle(ctx, sx, sy, sw, sh);       break;
            case 'well':       this._bldWell(ctx, sx, sy, sw, sh);         break;
            case 'garden':     this._bldGarden(ctx, sx, sy, sw, sh);       break;
            default:           this._bldGeneric(ctx, b, sx, sy, sw, sh);   break;
        }
    }

    /* ─── Per-type building drawers ──────────────────────────────────────── */

    _bldCottage(ctx, sx, sy, sw, sh, tier) {
        const roofH = sh * 0.42;
        const wallY = sy + roofH;
        const wallH = sh - roofH;
        const wallC = ['#c9956a','#d4a373','#e8c99a'][tier];
        const roofC = ['#8B3A2A','#A0522D','#6B3020'][tier];

        // Wall
        ctx.fillStyle = wallC;
        ctx.fillRect(sx, wallY, sw, wallH);
        ctx.fillStyle = 'rgba(0,0,0,0.12)';
        ctx.fillRect(sx + sw * 0.68, wallY, sw * 0.32, wallH);

        // Roof
        ctx.fillStyle = roofC;
        ctx.beginPath();
        ctx.moveTo(sx - sw * 0.07, wallY + 2);
        ctx.lineTo(sx + sw * 0.5, sy);
        ctx.lineTo(sx + sw * 1.07, wallY + 2);
        ctx.closePath();
        ctx.fill();
        ctx.fillStyle = 'rgba(255,255,255,0.1)';
        ctx.beginPath();
        ctx.moveTo(sx + sw * 0.18, wallY - roofH * 0.52);
        ctx.lineTo(sx + sw * 0.5, sy);
        ctx.lineTo(sx + sw * 0.3, wallY - roofH * 0.6);
        ctx.closePath();
        ctx.fill();

        // Chimney(s)
        const chimneys = tier === 2 ? [0.18, 0.74] : [0.75];
        for (const cx of chimneys) {
            ctx.fillStyle = '#7a4030';
            ctx.fillRect(sx + sw * cx, sy + roofH * 0.14, sw * 0.09, roofH * 0.58);
            ctx.fillStyle = 'rgba(170,170,170,0.45)';
            ctx.beginPath();
            ctx.arc(sx + sw * cx + sw * 0.045, sy + roofH * 0.1, sw * 0.055, 0, Math.PI * 2);
            ctx.fill();
        }

        // Door
        const dw = sw * 0.22, dh = wallH * 0.54;
        const dx = sx + sw * 0.5 - dw / 2, dy = wallY + wallH - dh;
        ctx.fillStyle = '#4a2810';
        ctx.fillRect(dx, dy, dw, dh);
        ctx.fillStyle = '#5a3820';
        ctx.beginPath();
        ctx.arc(dx + dw / 2, dy, dw / 2, Math.PI, 0);
        ctx.fill();
        ctx.fillStyle = '#d4a030';
        ctx.beginPath();
        ctx.arc(dx + dw * 0.72, dy + dh * 0.5, Math.max(1, sw * 0.024), 0, Math.PI * 2);
        ctx.fill();

        // Windows
        const winXs = tier === 0 ? [0.22] : tier === 1 ? [0.18, 0.8] : [0.12, 0.5, 0.85];
        const ww = sw * 0.14, wh = wallH * 0.3, wy = wallY + wallH * 0.16;
        for (const wx2 of winXs) {
            const x2 = sx + sw * wx2 - ww / 2;
            ctx.fillStyle = 'rgba(200,235,255,0.88)';
            ctx.fillRect(x2, wy, ww, wh);
            ctx.fillStyle = '#7a5030';
            ctx.fillRect(x2 + ww / 2 - 1, wy, 2, wh);
            ctx.fillRect(x2, wy + wh / 2 - 1, ww, 2);
            ctx.strokeStyle = '#5a3820';
            ctx.lineWidth = 1;
            ctx.strokeRect(x2, wy, ww, wh);
        }

        // Base
        ctx.fillStyle = 'rgba(0,0,0,0.15)';
        ctx.fillRect(sx, sy + sh - 3, sw, 3);
    }

    _bldMansion(ctx, sx, sy, sw, sh) {
        this._bldCottage(ctx, sx, sy, sw, sh, 2);
        const ww = sw * 0.16, wh = sh * 0.42, wy2 = sy + sh - wh;
        ctx.fillStyle = '#e0c090';
        ctx.fillRect(sx - ww, wy2, ww, wh);
        ctx.fillRect(sx + sw, wy2, ww, wh);
        ctx.fillStyle = '#8B3A2A';
        ctx.beginPath();
        ctx.moveTo(sx - ww * 1.04, wy2);
        ctx.lineTo(sx - ww * 0.5, wy2 - wh * 0.38);
        ctx.lineTo(sx, wy2);
        ctx.closePath();
        ctx.fill();
        ctx.beginPath();
        ctx.moveTo(sx + sw, wy2);
        ctx.lineTo(sx + sw + ww * 0.5, wy2 - wh * 0.38);
        ctx.lineTo(sx + sw + ww * 1.04, wy2);
        ctx.closePath();
        ctx.fill();
    }

    _bldFarm(ctx, sx, sy, sw, sh) {
        // Left field
        ctx.fillStyle = '#6a8a3a';
        ctx.fillRect(sx, sy + sh * 0.28, sw * 0.28, sh * 0.72);
        ctx.strokeStyle = '#4a6a1a';
        ctx.lineWidth = 1;
        for (let i = 0; i <= 5; i++) {
            const fy = sy + sh * 0.28 + (sh * 0.72 / 5) * i;
            ctx.beginPath(); ctx.moveTo(sx, fy); ctx.lineTo(sx + sw * 0.28, fy); ctx.stroke();
        }
        // Right field
        ctx.fillStyle = '#7aaa4a';
        ctx.fillRect(sx + sw * 0.72, sy + sh * 0.28, sw * 0.28, sh * 0.72);
        for (let i = 0; i <= 5; i++) {
            const fy = sy + sh * 0.28 + (sh * 0.72 / 5) * i;
            ctx.beginPath(); ctx.moveTo(sx + sw * 0.72, fy); ctx.lineTo(sx + sw, fy); ctx.stroke();
        }
        // Barn
        ctx.fillStyle = '#a0602a';
        ctx.fillRect(sx + sw * 0.3, sy + sh * 0.4, sw * 0.4, sh * 0.6);
        ctx.fillStyle = 'rgba(0,0,0,0.15)';
        ctx.fillRect(sx + sw * 0.56, sy + sh * 0.4, sw * 0.14, sh * 0.6);
        // Barn roof
        ctx.fillStyle = '#7a3010';
        ctx.beginPath();
        ctx.moveTo(sx + sw * 0.25, sy + sh * 0.4);
        ctx.lineTo(sx + sw * 0.5,  sy + sh * 0.08);
        ctx.lineTo(sx + sw * 0.75, sy + sh * 0.4);
        ctx.closePath();
        ctx.fill();
        // Barn doors
        ctx.fillStyle = '#5a3010';
        ctx.fillRect(sx + sw * 0.36, sy + sh * 0.65, sw * 0.12, sh * 0.35);
        ctx.fillRect(sx + sw * 0.52, sy + sh * 0.65, sw * 0.12, sh * 0.35);
        // Fence
        ctx.strokeStyle = '#a07040';
        ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.moveTo(sx, sy + sh - 3); ctx.lineTo(sx + sw, sy + sh - 3); ctx.stroke();
        for (let i = 0; i <= 6; i++) {
            const px = sx + (sw / 6) * i;
            ctx.beginPath(); ctx.moveTo(px, sy + sh * 0.6); ctx.lineTo(px, sy + sh); ctx.stroke();
        }
    }

    _bldHunting(ctx, sx, sy, sw, sh) {
        const wallY = sy + sh * 0.46, wallH = sh * 0.54;
        // Trees behind
        for (const [tx, flip] of [[sx, 1], [sx + sw * 0.8, -1]]) {
            ctx.fillStyle = '#1a5020';
            ctx.beginPath();
            ctx.moveTo(tx + sw * 0.07, sy + sh * 0.1);
            ctx.lineTo(tx + sw * 0.14, sy + sh * 0.45);
            ctx.lineTo(tx, sy + sh * 0.45);
            ctx.closePath();
            ctx.fill();
        }
        // Log walls
        ctx.fillStyle = '#8a5e3a';
        ctx.fillRect(sx + sw * 0.1, wallY, sw * 0.8, wallH);
        ctx.strokeStyle = '#6a4020'; ctx.lineWidth = 1.5;
        for (let i = 1; i < 4; i++) {
            ctx.beginPath();
            ctx.moveTo(sx + sw * 0.1, wallY + wallH * i / 4);
            ctx.lineTo(sx + sw * 0.9, wallY + wallH * i / 4);
            ctx.stroke();
        }
        ctx.fillStyle = 'rgba(0,0,0,0.15)';
        ctx.fillRect(sx + sw * 0.66, wallY, sw * 0.24, wallH);
        // Roof
        ctx.fillStyle = '#5a3820';
        ctx.beginPath();
        ctx.moveTo(sx + sw * 0.04, wallY + 1);
        ctx.lineTo(sx + sw * 0.5, sy + sh * 0.06);
        ctx.lineTo(sx + sw * 0.96, wallY + 1);
        ctx.closePath();
        ctx.fill();
        // Door
        ctx.fillStyle = '#3a2010';
        ctx.fillRect(sx + sw * 0.4, wallY + wallH * 0.35, sw * 0.2, wallH * 0.65);
        // Antlers
        ctx.strokeStyle = '#c09060'; ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.moveTo(sx + sw * 0.42, wallY + wallH * 0.14); ctx.lineTo(sx + sw * 0.37, wallY - sh * 0.1); ctx.lineTo(sx + sw * 0.32, wallY - sh * 0.16); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(sx + sw * 0.58, wallY + wallH * 0.14); ctx.lineTo(sx + sw * 0.63, wallY - sh * 0.1); ctx.lineTo(sx + sw * 0.68, wallY - sh * 0.16); ctx.stroke();
    }

    _bldFishery(ctx, sx, sy, sw, sh) {
        const wallY = sy + sh - sh * 0.15 - sh * 0.48, wallH = sh * 0.48;
        // Stilts
        ctx.strokeStyle = '#7a5020';
        ctx.lineWidth = Math.max(1.5, sw * 0.04);
        for (const px of [0.2, 0.5, 0.8]) {
            ctx.beginPath();
            ctx.moveTo(sx + sw * px, wallY + wallH);
            ctx.lineTo(sx + sw * px, sy + sh);
            ctx.stroke();
        }
        // Dock
        ctx.fillStyle = '#a07040';
        ctx.fillRect(sx + sw * 0.62, wallY + wallH * 0.5, sw * 0.48, sh * 0.07);
        // Wall
        ctx.fillStyle = '#9abccc';
        ctx.fillRect(sx + sw * 0.1, wallY, sw * 0.7, wallH);
        ctx.fillStyle = 'rgba(0,0,0,0.12)';
        ctx.fillRect(sx + sw * 0.55, wallY, sw * 0.25, wallH);
        // Roof
        ctx.fillStyle = '#5a7a8a';
        ctx.beginPath();
        ctx.moveTo(sx + sw * 0.04, wallY + 1);
        ctx.lineTo(sx + sw * 0.45, sy + sh * 0.18);
        ctx.lineTo(sx + sw * 0.86, wallY + 1);
        ctx.closePath();
        ctx.fill();
        // Door
        ctx.fillStyle = '#2a4050';
        ctx.fillRect(sx + sw * 0.34, wallY + wallH * 0.4, sw * 0.16, wallH * 0.6);
        // Window
        ctx.fillStyle = 'rgba(180,220,255,0.85)';
        ctx.fillRect(sx + sw * 0.57, wallY + wallH * 0.14, sw * 0.14, wallH * 0.26);
    }

    _bldLumbermill(ctx, sx, sy, sw, sh) {
        const wallY = sy + sh * 0.45, wallH = sh * 0.55;
        // Log pile
        for (let i = 0; i < 3; i++) {
            ctx.fillStyle = i % 2 === 0 ? '#a06030' : '#8a4820';
            ctx.fillRect(sx + sw * 0.02, wallY + wallH * 0.35 - i * sh * 0.07, sw * 0.2, sh * 0.08);
        }
        // Shed wall
        ctx.fillStyle = '#b07840';
        ctx.fillRect(sx + sw * 0.24, wallY, sw * 0.76, wallH);
        ctx.fillStyle = 'rgba(0,0,0,0.14)';
        ctx.fillRect(sx + sw * 0.74, wallY, sw * 0.26, wallH);
        // Roof (lean-to)
        ctx.fillStyle = '#6a4020';
        ctx.beginPath();
        ctx.moveTo(sx + sw * 0.18, wallY);
        ctx.lineTo(sx + sw * 0.58, sy + sh * 0.02);
        ctx.lineTo(sx + sw * 1.03, sy + sh * 0.12);
        ctx.lineTo(sx + sw * 1.03, wallY);
        ctx.closePath();
        ctx.fill();
        // Saw blade
        const bx = sx + sw * 0.7, by = wallY + wallH * 0.5, br = sh * 0.2;
        ctx.fillStyle = '#d0d0c0';
        ctx.beginPath(); ctx.arc(bx, by, br, 0, Math.PI * 2); ctx.fill();
        ctx.strokeStyle = '#888870'; ctx.lineWidth = 1; ctx.stroke();
        for (let i = 0; i < 10; i++) {
            const a = i / 10 * Math.PI * 2;
            ctx.beginPath();
            ctx.moveTo(bx + Math.cos(a) * br, by + Math.sin(a) * br);
            ctx.lineTo(bx + Math.cos(a) * (br + sh * 0.05), by + Math.sin(a) * (br + sh * 0.05));
            ctx.stroke();
        }
        ctx.fillStyle = '#888';
        ctx.beginPath(); ctx.arc(bx, by, br * 0.14, 0, Math.PI * 2); ctx.fill();
        // Door
        ctx.fillStyle = '#4a2810';
        ctx.fillRect(sx + sw * 0.36, wallY + wallH * 0.4, sw * 0.15, wallH * 0.6);
    }

    _bldQuarry(ctx, sx, sy, sw, sh) {
        ctx.fillStyle = '#7a7060';
        ctx.fillRect(sx, sy + sh * 0.28, sw, sh * 0.72);
        ctx.fillStyle = '#9a8a7a';
        ctx.fillRect(sx + sw * 0.1, sy + sh * 0.44, sw * 0.8, sh * 0.56);
        ctx.fillStyle = '#b0a090';
        ctx.fillRect(sx + sw * 0.25, sy + sh * 0.6, sw * 0.5, sh * 0.4);
        // Rock pile
        for (let i = 0; i < 4; i++) {
            ctx.fillStyle = i % 2 === 0 ? '#9a9088' : '#8a8070';
            ctx.beginPath();
            ctx.moveTo(sx + sw * (0.04 + i * 0.22), sy + sh * 0.3);
            ctx.lineTo(sx + sw * (0.04 + i * 0.22 + 0.1), sy + sh * 0.22);
            ctx.lineTo(sx + sw * (0.04 + i * 0.22 + 0.2), sy + sh * 0.3);
            ctx.closePath();
            ctx.fill();
        }
        // Hut
        ctx.fillStyle = '#b09878';
        ctx.fillRect(sx + sw * 0.7, sy + sh * 0.08, sw * 0.28, sh * 0.3);
        ctx.fillStyle = '#7a5030';
        ctx.beginPath();
        ctx.moveTo(sx + sw * 0.68, sy + sh * 0.08);
        ctx.lineTo(sx + sw * 0.84, sy - sh * 0.04);
        ctx.lineTo(sx + sw * 1.0,  sy + sh * 0.08);
        ctx.closePath();
        ctx.fill();
        // Crane
        ctx.strokeStyle = '#8a6030'; ctx.lineWidth = Math.max(1.5, sw * 0.025);
        ctx.beginPath(); ctx.moveTo(sx + sw * 0.3, sy + sh * 0.62); ctx.lineTo(sx + sw * 0.5, sy + sh * 0.3); ctx.lineTo(sx + sw * 0.7, sy + sh * 0.38); ctx.stroke();
        ctx.strokeStyle = '#c0a060'; ctx.lineWidth = 1;
        ctx.beginPath(); ctx.moveTo(sx + sw * 0.7, sy + sh * 0.38); ctx.lineTo(sx + sw * 0.7, sy + sh * 0.58); ctx.stroke();
        ctx.fillStyle = '#9a8a7a';
        ctx.fillRect(sx + sw * 0.66, sy + sh * 0.57, sw * 0.08, sh * 0.07);
    }

    _bldSmithy(ctx, sx, sy, sw, sh, time) {
        const wallY = sy + sh * 0.38, wallH = sh * 0.62;
        // Stone walls
        ctx.fillStyle = '#6a5040';
        ctx.fillRect(sx + sw * 0.05, wallY, sw * 0.9, wallH);
        ctx.fillStyle = '#5a4030';
        for (let r = 0; r < 3; r++) for (let c = 0; c < 3; c++) {
            if ((r + c) % 2 === 0)
                ctx.fillRect(sx + sw * (0.05 + c * 0.3), wallY + wallH * r * 0.33, sw * 0.28, wallH * 0.31);
        }
        ctx.fillStyle = 'rgba(0,0,0,0.2)';
        ctx.fillRect(sx + sw * 0.7, wallY, sw * 0.25, wallH);
        // Roof
        ctx.fillStyle = '#3a2818';
        ctx.beginPath();
        ctx.moveTo(sx, wallY + 1);
        ctx.lineTo(sx + sw * 0.5, sy + sh * 0.08);
        ctx.lineTo(sx + sw, wallY + 1);
        ctx.closePath();
        ctx.fill();
        // Chimney
        const cx2 = sx + sw * 0.22;
        ctx.fillStyle = '#4a3020';
        ctx.fillRect(cx2, sy, sw * 0.14, sh * 0.5);
        ctx.fillStyle = '#2a1808';
        ctx.fillRect(cx2 - sw * 0.02, sy - sh * 0.03, sw * 0.18, sh * 0.04);
        // Animated glow
        const t = time * 0.001;
        const ga = 0.5 + 0.4 * Math.sin(t * 4);
        ctx.fillStyle = `rgba(255,100,0,${ga * 0.7})`;
        ctx.beginPath(); ctx.arc(cx2 + sw * 0.07, sy - sh * 0.02, sw * 0.1, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = `rgba(180,60,0,${ga * 0.5})`;
        ctx.beginPath(); ctx.arc(cx2 + sw * 0.07, sy - sh * 0.09, sw * 0.07, 0, Math.PI * 2); ctx.fill();
        // Door glow + darkness
        const fdx = sx + sw * 0.38;
        ctx.fillStyle = `rgba(255,140,0,${0.38 + 0.28 * Math.sin(t * 7)})`;
        ctx.fillRect(fdx, wallY + wallH * 0.34, sw * 0.22, wallH * 0.66);
        ctx.fillStyle = '#1a0a00';
        ctx.fillRect(fdx + sw * 0.02, wallY + wallH * 0.37, sw * 0.18, wallH * 0.63);
        // Glowing window
        ctx.fillStyle = `rgba(255,180,50,${0.6 + 0.28 * Math.sin(t * 5)})`;
        ctx.fillRect(sx + sw * 0.67, wallY + wallH * 0.18, sw * 0.16, wallH * 0.22);
    }

    _bldMine(ctx, sx, sy, sw, sh) {
        ctx.fillStyle = '#7a7060';
        ctx.beginPath();
        ctx.moveTo(sx, sy + sh);
        ctx.lineTo(sx + sw * 0.1, sy + sh * 0.34);
        ctx.lineTo(sx + sw * 0.4, sy + sh * 0.1);
        ctx.lineTo(sx + sw * 0.7, sy + sh * 0.24);
        ctx.lineTo(sx + sw, sy + sh * 0.4);
        ctx.lineTo(sx + sw, sy + sh);
        ctx.closePath();
        ctx.fill();
        // Entrance
        ctx.fillStyle = '#1a1008';
        ctx.beginPath();
        ctx.arc(sx + sw * 0.3, sy + sh * 0.62, sw * 0.17, Math.PI, 0);
        ctx.rect(sx + sw * 0.13, sy + sh * 0.62, sw * 0.34, sh * 0.38);
        ctx.fill();
        // Frame
        ctx.strokeStyle = '#8a5030'; ctx.lineWidth = Math.max(2, sw * 0.04);
        ctx.beginPath(); ctx.moveTo(sx + sw * 0.13, sy + sh); ctx.lineTo(sx + sw * 0.13, sy + sh * 0.6); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(sx + sw * 0.47, sy + sh); ctx.lineTo(sx + sw * 0.47, sy + sh * 0.6); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(sx + sw * 0.1, sy + sh * 0.62); ctx.lineTo(sx + sw * 0.5, sy + sh * 0.62); ctx.stroke();
        // Ore pile
        ctx.fillStyle = '#9a8060';
        ctx.beginPath();
        ctx.ellipse(sx + sw * 0.72, sy + sh * 0.78, sw * 0.2, sh * 0.12, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = '#c0a850';
        for (let i = 0; i < 4; i++) {
            ctx.beginPath();
            ctx.arc(sx + sw * (0.58 + i * 0.06), sy + sh * (0.72 + (i % 2) * 0.06), sw * 0.025, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    _bldMarket(ctx, sx, sy, sw, sh) {
        ctx.fillStyle = '#c8b870';
        ctx.fillRect(sx, sy + sh * 0.5, sw, sh * 0.5);
        const stallW = sw * 0.3;
        const colors = ['#e84040','#e8c040','#4080e8'];
        const xp = [0.02, 0.36, 0.68];
        for (let i = 0; i < 3; i++) {
            const stx = sx + sw * xp[i];
            const sty = sy + sh * 0.3;
            ctx.fillStyle = '#8a6030';
            ctx.fillRect(stx + stallW * 0.02, sty, stallW * 0.06, sh * 0.5);
            ctx.fillRect(stx + stallW * 0.72, sty, stallW * 0.06, sh * 0.5);
            ctx.fillStyle = colors[i];
            ctx.beginPath();
            ctx.moveTo(stx + stallW * 0.1, sty);
            ctx.lineTo(stx + stallW * 0.9, sty);
            ctx.lineTo(stx + stallW * 1.04, sty + sh * 0.025);
            ctx.lineTo(stx - stallW * 0.04, sty + sh * 0.025);
            ctx.closePath();
            ctx.fill();
            ctx.fillStyle = 'rgba(255,255,255,0.3)';
            for (let s = 0; s < 3; s++)
                ctx.fillRect(stx + stallW * (0.12 + s * 0.28), sty, stallW * 0.08, sh * 0.025);
            ctx.fillStyle = '#c09050';
            ctx.fillRect(stx + stallW * 0.05, sty + sh * 0.1, stallW * 0.9, sh * 0.1);
            ctx.fillStyle = colors[(i + 1) % 3];
            for (let g = 0; g < 3; g++) {
                ctx.beginPath();
                ctx.arc(stx + stallW * (0.2 + g * 0.3), sty + sh * 0.14, sh * 0.04, 0, Math.PI * 2);
                ctx.fill();
            }
        }
        ctx.strokeStyle = '#a09050'; ctx.lineWidth = 1;
        for (let c = 0; c < 4; c++) for (let r = 0; r < 2; r++) {
            ctx.strokeRect(sx + sw * 0.04 + c * sw * 0.23, sy + sh * 0.55 + r * sh * 0.2, sw * 0.21, sh * 0.19);
        }
    }

    _bldTavern(ctx, sx, sy, sw, sh) {
        const wallY = sy + sh * 0.38, wallH = sh * 0.62;
        ctx.fillStyle = '#d4a050';
        ctx.fillRect(sx, wallY, sw, wallH);
        ctx.fillStyle = 'rgba(0,0,0,0.13)';
        ctx.fillRect(sx + sw * 0.72, wallY, sw * 0.28, wallH);
        // Thatch roof
        ctx.fillStyle = '#9a7830';
        ctx.beginPath();
        ctx.moveTo(sx - sw * 0.04, wallY + 1);
        ctx.lineTo(sx + sw * 0.5, sy + sh * 0.04);
        ctx.lineTo(sx + sw * 1.04, wallY + 1);
        ctx.closePath();
        ctx.fill();
        ctx.strokeStyle = '#7a5820'; ctx.lineWidth = 1;
        for (let i = 1; i < 5; i++) {
            const ratio = i / 5;
            ctx.beginPath();
            ctx.moveTo(sx - sw * 0.04 + (sw * 0.54) * ratio, wallY + 1 - (wallY - sy - sh * 0.04) * ratio);
            ctx.lineTo(sx + sw * 0.5, sy + sh * 0.04);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(sx + sw * 1.04 - (sw * 0.54) * ratio, wallY + 1 - (wallY - sy - sh * 0.04) * ratio);
            ctx.lineTo(sx + sw * 0.5, sy + sh * 0.04);
            ctx.stroke();
        }
        // Chimney + smoke
        ctx.fillStyle = '#8a5030';
        ctx.fillRect(sx + sw * 0.15, sy + sh * 0.06, sw * 0.1, sh * 0.34);
        ctx.fillStyle = 'rgba(160,160,160,0.5)';
        ctx.beginPath(); ctx.arc(sx + sw * 0.2, sy + sh * 0.04, sw * 0.08, 0, Math.PI * 2); ctx.fill();
        // Double door
        ctx.fillStyle = '#5a3018';
        ctx.fillRect(sx + sw * 0.37, wallY + wallH * 0.3, sw * 0.26, wallH * 0.7);
        ctx.strokeStyle = '#3a1800'; ctx.lineWidth = 1;
        ctx.beginPath(); ctx.moveTo(sx + sw * 0.5, wallY + wallH * 0.3); ctx.lineTo(sx + sw * 0.5, sy + sh); ctx.stroke();
        ctx.fillStyle = '#6a4020';
        ctx.beginPath(); ctx.arc(sx + sw * 0.5, wallY + wallH * 0.3, sw * 0.13, Math.PI, 0); ctx.fill();
        // Windows (warm glow)
        ctx.fillStyle = 'rgba(255,200,100,0.85)';
        ctx.fillRect(sx + sw * 0.06, wallY + wallH * 0.17, sw * 0.2, wallH * 0.28);
        ctx.fillRect(sx + sw * 0.74, wallY + wallH * 0.17, sw * 0.2, wallH * 0.28);
        ctx.strokeStyle = '#5a3018'; ctx.lineWidth = 1.5;
        ctx.strokeRect(sx + sw * 0.06, wallY + wallH * 0.17, sw * 0.2, wallH * 0.28);
        ctx.strokeRect(sx + sw * 0.74, wallY + wallH * 0.17, sw * 0.2, wallH * 0.28);
        // Hanging sign
        ctx.fillStyle = '#6a4010';
        ctx.fillRect(sx + sw * 0.63, wallY - sh * 0.09, sw * 0.02, sh * 0.13);
        ctx.fillStyle = '#c08030';
        ctx.fillRect(sx + sw * 0.54, wallY - sh * 0.11, sw * 0.28, sh * 0.09);
        ctx.fillStyle = '#1a0a00';
        ctx.font = `bold ${Math.max(4, sh * 0.056)}px serif`;
        ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
        ctx.fillText('INN', sx + sw * 0.68, wallY - sh * 0.065);
    }

    _bldTownhall(ctx, sx, sy, sw, sh, time) {
        const mainW = sw * 0.7, mainX = sx + sw * 0.15;
        const wallY = sy + sh * 0.44, wallH = sh * 0.56;

        // Steps
        ctx.fillStyle = '#c8b890';
        ctx.fillRect(sx + sw * 0.26, sy + sh - sh * 0.06, sw * 0.48, sh * 0.06);
        ctx.fillRect(sx + sw * 0.3, sy + sh - sh * 0.1, sw * 0.4, sh * 0.04);

        // Side wings
        ctx.fillStyle = '#b8a070';
        ctx.fillRect(sx, wallY + sh * 0.08, sw * 0.16, wallH - sh * 0.08);
        ctx.fillRect(sx + sw * 0.84, wallY + sh * 0.08, sw * 0.16, wallH - sh * 0.08);
        ctx.fillStyle = '#8a6830';
        for (const [wx2, flip] of [[sx, 1], [sx + sw * 0.84, -1]]) {
            ctx.beginPath();
            ctx.moveTo(wx2 + (flip > 0 ? -sw * 0.01 : 0), wallY + sh * 0.09);
            ctx.lineTo(wx2 + (flip > 0 ? sw * 0.08 : sw * 0.08), wallY - sh * 0.04);
            ctx.lineTo(wx2 + (flip > 0 ? sw * 0.17 : sw * 0.16), wallY + sh * 0.09);
            ctx.closePath();
            ctx.fill();
        }

        // Main wall
        ctx.fillStyle = '#d4b870';
        ctx.fillRect(mainX, wallY, mainW, wallH);
        ctx.fillStyle = 'rgba(0,0,0,0.12)';
        ctx.fillRect(mainX + mainW * 0.72, wallY, mainW * 0.28, wallH);

        // Columns
        ctx.fillStyle = '#e0cc90';
        for (let i = 0; i < 4; i++) {
            const colX = mainX + mainW * (0.1 + i * 0.25);
            ctx.fillRect(colX, wallY - sh * 0.02, mainW * 0.04, wallH * 0.84);
            ctx.fillRect(colX - mainW * 0.02, wallY - sh * 0.02, mainW * 0.08, sh * 0.03);
        }

        // Pediment roof
        ctx.fillStyle = '#9a7830';
        ctx.beginPath();
        ctx.moveTo(mainX - sw * 0.03, wallY);
        ctx.lineTo(mainX + mainW * 0.5, sy + sh * 0.18);
        ctx.lineTo(mainX + mainW + sw * 0.03, wallY);
        ctx.closePath();
        ctx.fill();

        // Clock tower
        const tw = sw * 0.17, tx = sx + sw * 0.415;
        const tBase = sy + sh * 0.18;
        ctx.fillStyle = '#c8a060';
        ctx.fillRect(tx, tBase, tw, wallY - tBase + sh * 0.05);
        // Tower window
        ctx.fillStyle = 'rgba(180,210,255,0.85)';
        ctx.fillRect(tx + tw * 0.2, tBase + (wallY - tBase) * 0.15, tw * 0.6, (wallY - tBase) * 0.26);
        // Clock face
        ctx.fillStyle = '#e8d8a0';
        ctx.beginPath();
        ctx.arc(tx + tw / 2, tBase - (wallY - tBase) * 0.1, tw * 0.36, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = '#8a6020'; ctx.lineWidth = 1.5; ctx.stroke();
        // Clock hands
        const t = time * 0.0003;
        ctx.strokeStyle = '#3a2010'; ctx.lineWidth = 1.5;
        const hcx = tx + tw / 2, hcy = tBase - (wallY - tBase) * 0.1;
        ctx.beginPath();
        ctx.moveTo(hcx, hcy);
        ctx.lineTo(hcx + Math.cos(t) * tw * 0.24, hcy + Math.sin(t) * tw * 0.24);
        ctx.stroke();
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(hcx, hcy);
        ctx.lineTo(hcx + Math.cos(t * 12) * tw * 0.32, hcy + Math.sin(t * 12) * tw * 0.32);
        ctx.stroke();
        // Spire
        ctx.fillStyle = '#7a5820';
        ctx.beginPath();
        ctx.moveTo(tx, tBase);
        ctx.lineTo(tx + tw / 2, sy);
        ctx.lineTo(tx + tw, tBase);
        ctx.closePath();
        ctx.fill();
        // Animated flag
        const ft = time * 0.002;
        ctx.fillStyle = '#cc2020';
        ctx.beginPath();
        ctx.moveTo(tx + tw / 2, sy);
        ctx.lineTo(tx + tw / 2 + sw * 0.1 + Math.sin(ft) * sw * 0.04, sy + sh * 0.03);
        ctx.lineTo(tx + tw / 2, sy + sh * 0.06);
        ctx.closePath();
        ctx.fill();

        // Main door
        ctx.fillStyle = '#5a4010';
        ctx.fillRect(mainX + mainW * 0.37, wallY + wallH * 0.35, mainW * 0.26, wallH * 0.65);
        ctx.fillStyle = '#6a5020';
        ctx.beginPath();
        ctx.arc(mainX + mainW * 0.5, wallY + wallH * 0.35, mainW * 0.13, Math.PI, 0);
        ctx.fill();
    }

    _bldChurch(ctx, sx, sy, sw, sh) {
        const wallY = sy + sh * 0.47, wallH = sh * 0.53;
        const naveW = sw * 0.64, naveX = sx + sw * 0.18;

        ctx.fillStyle = '#d4c5a9';
        ctx.fillRect(naveX, wallY, naveW, wallH);
        ctx.fillStyle = 'rgba(0,0,0,0.12)';
        ctx.fillRect(naveX + naveW * 0.72, wallY, naveW * 0.28, wallH);
        ctx.fillStyle = '#9a8a6a';
        ctx.beginPath();
        ctx.moveTo(naveX - sw * 0.02, wallY);
        ctx.lineTo(naveX + naveW / 2, sy + sh * 0.22);
        ctx.lineTo(naveX + naveW + sw * 0.02, wallY);
        ctx.closePath();
        ctx.fill();

        // Bell tower
        const btW = sw * 0.24, btX = sx + sw * 0.38;
        const btBase = sy + sh * 0.1;
        ctx.fillStyle = '#c8b890';
        ctx.fillRect(btX, btBase, btW, wallY - btBase);
        ctx.fillStyle = '#88776a';
        ctx.beginPath(); ctx.arc(btX + btW * 0.3, btBase + (wallY - btBase) * 0.13, btW * 0.22, Math.PI, 0); ctx.fill();
        ctx.beginPath(); ctx.arc(btX + btW * 0.7, btBase + (wallY - btBase) * 0.13, btW * 0.22, Math.PI, 0); ctx.fill();
        ctx.fillStyle = '#7a6a50';
        ctx.beginPath();
        ctx.moveTo(btX + btW * 0.1, btBase);
        ctx.lineTo(btX + btW * 0.5, sy - sh * 0.12);
        ctx.lineTo(btX + btW * 0.9, btBase);
        ctx.closePath();
        ctx.fill();
        // Cross
        const cxp = btX + btW * 0.5, cyp = sy - sh * 0.08;
        ctx.strokeStyle = '#f0e8d0'; ctx.lineWidth = Math.max(1.5, sw * 0.025);
        ctx.beginPath(); ctx.moveTo(cxp, sy - sh * 0.14); ctx.lineTo(cxp, cyp + sh * 0.07); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(cxp - sw * 0.05, cyp); ctx.lineTo(cxp + sw * 0.05, cyp); ctx.stroke();

        // Gothic windows
        const winXs2 = [0.22, 0.44, 0.66];
        for (const wx2 of winXs2) {
            const x2 = naveX + naveW * wx2, y2 = wallY + wallH * 0.16;
            const ww = naveW * 0.11, wh = wallH * 0.32;
            ctx.fillStyle = 'rgba(180,210,255,0.8)';
            ctx.fillRect(x2, y2 + wh * 0.25, ww, wh * 0.75);
            ctx.beginPath(); ctx.arc(x2 + ww / 2, y2 + wh * 0.25, ww / 2, Math.PI, 0); ctx.fill();
            ctx.strokeStyle = '#9a8a6a'; ctx.lineWidth = 1;
            ctx.strokeRect(x2, y2 + wh * 0.25, ww, wh * 0.75);
        }
        ctx.fillStyle = '#5a4030';
        ctx.fillRect(naveX + naveW * 0.38, wallY + wallH * 0.42, naveW * 0.24, wallH * 0.58);
        ctx.fillStyle = '#4a3020';
        ctx.beginPath(); ctx.arc(naveX + naveW * 0.5, wallY + wallH * 0.42, naveW * 0.12, Math.PI, 0); ctx.fill();
    }

    _bldSchool(ctx, sx, sy, sw, sh) {
        const wallY = sy + sh * 0.4, wallH = sh * 0.6;
        ctx.fillStyle = '#8ab4d4';
        ctx.fillRect(sx + sw * 0.05, wallY, sw * 0.9, wallH);
        ctx.fillStyle = 'rgba(0,0,0,0.12)';
        ctx.fillRect(sx + sw * 0.7, wallY, sw * 0.25, wallH);
        ctx.fillStyle = '#4a7494';
        ctx.beginPath();
        ctx.moveTo(sx, wallY + 1);
        ctx.lineTo(sx + sw / 2, sy + sh * 0.1);
        ctx.lineTo(sx + sw, wallY + 1);
        ctx.closePath();
        ctx.fill();
        // Bell tower
        const btX = sx + sw * 0.44;
        ctx.fillStyle = '#6a94b4';
        ctx.fillRect(btX, sy + sh * 0.04, sw * 0.12, sh * 0.1);
        ctx.fillStyle = '#3a6484';
        ctx.beginPath(); ctx.moveTo(btX, sy + sh * 0.04); ctx.lineTo(btX + sw * 0.06, sy); ctx.lineTo(btX + sw * 0.12, sy + sh * 0.04); ctx.closePath(); ctx.fill();
        ctx.fillStyle = '#d4a020';
        ctx.beginPath(); ctx.arc(btX + sw * 0.06, sy + sh * 0.1, sw * 0.03, Math.PI, 0); ctx.fill();
        // Windows
        const winY2 = wallY + wallH * 0.14;
        for (let i = 0; i < 3; i++) {
            const wx2 = sx + sw * (0.1 + i * 0.28);
            ctx.fillStyle = 'rgba(200,230,255,0.85)';
            ctx.fillRect(wx2, winY2, sw * 0.18, wallH * 0.3);
            ctx.strokeStyle = '#3a6484'; ctx.lineWidth = 1.5;
            ctx.strokeRect(wx2, winY2, sw * 0.18, wallH * 0.3);
            ctx.beginPath(); ctx.moveTo(wx2 + sw * 0.09, winY2); ctx.lineTo(wx2 + sw * 0.09, winY2 + wallH * 0.3); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(wx2, winY2 + wallH * 0.15); ctx.lineTo(wx2 + sw * 0.18, winY2 + wallH * 0.15); ctx.stroke();
        }
        ctx.fillStyle = '#2a4a6a';
        ctx.fillRect(sx + sw * 0.41, wallY + wallH * 0.45, sw * 0.18, wallH * 0.55);
    }

    _bldCastle(ctx, sx, sy, sw, sh) {
        const wallY = sy + sh * 0.53, wallH = sh * 0.47;
        // Curtain wall
        ctx.fillStyle = '#907060';
        ctx.fillRect(sx + sw * 0.05, wallY + sh * 0.04, sw * 0.9, wallH - sh * 0.04);
        // Merlons
        ctx.fillStyle = '#807060';
        for (let i = 0; i < 8; i++) {
            if (i % 2 === 0)
                ctx.fillRect(sx + sw * 0.05 + (i / 8) * sw * 0.9, wallY, sw * 0.9 / 8, sh * 0.06);
        }
        // Main keep
        const kw = sw * 0.36, kx = sx + sw * 0.32;
        ctx.fillStyle = '#a08070';
        ctx.fillRect(kx, sy + sh * 0.0, kw, wallY - sy + sh * 0.06);
        ctx.fillStyle = 'rgba(0,0,0,0.15)';
        ctx.fillRect(kx + kw * 0.66, sy, kw * 0.34, wallY - sy + sh * 0.06);
        ctx.fillStyle = '#907060';
        for (let i = 0; i < 5; i++) {
            if (i % 2 === 0)
                ctx.fillRect(kx + (i / 5) * kw, sy + sh * 0.0, kw / 5, sh * 0.05);
        }
        // Corner towers
        const ltw = sw * 0.22;
        for (const [tx2, flip] of [[sx + sw * 0.02, 1], [sx + sw * 0.76, 1]]) {
            ctx.fillStyle = '#9a7a68';
            ctx.fillRect(tx2, sy + sh * 0.08, ltw, wallY - sy + sh * 0.06);
            ctx.fillStyle = '#604030';
            ctx.beginPath();
            ctx.moveTo(tx2 - ltw * 0.1, sy + sh * 0.08);
            ctx.lineTo(tx2 + ltw / 2, sy + sh * 0.08 - sh * 0.12);
            ctx.lineTo(tx2 + ltw * 1.1, sy + sh * 0.08);
            ctx.closePath();
            ctx.fill();
        }
        // Gate
        ctx.fillStyle = '#1a1008';
        ctx.beginPath();
        ctx.arc(sx + sw * 0.5, wallY + sh * 0.04, sw * 0.1, Math.PI, 0);
        ctx.rect(sx + sw * 0.4, wallY + sh * 0.04, sw * 0.2, sh * 0.22);
        ctx.fill();
        ctx.strokeStyle = '#5a4030'; ctx.lineWidth = 1;
        for (let b2 = 0; b2 < 3; b2++) {
            ctx.beginPath();
            ctx.moveTo(sx + sw * (0.43 + b2 * 0.065), wallY + sh * 0.04);
            ctx.lineTo(sx + sw * (0.43 + b2 * 0.065), wallY + sh * 0.26);
            ctx.stroke();
        }
        // Arrow slits
        ctx.fillStyle = '#1a1008';
        ctx.fillRect(kx + kw * 0.42, sy + sh * 0.1, kw * 0.08, sh * 0.12);
        // Flag
        ctx.fillStyle = '#cc2020';
        ctx.beginPath();
        ctx.moveTo(kx + kw / 2, sy);
        ctx.lineTo(kx + kw / 2 + sw * 0.08, sy + sh * 0.04);
        ctx.lineTo(kx + kw / 2, sy + sh * 0.08);
        ctx.closePath();
        ctx.fill();
        ctx.strokeStyle = '#7a4020'; ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.moveTo(kx + kw / 2, sy); ctx.lineTo(kx + kw / 2, sy - sh * 0.08); ctx.stroke();
    }

    _bldWell(ctx, sx, sy, sw, sh) {
        const cx = sx + sw / 2, cy = sy + sh * 0.62, r = sw * 0.36;
        ctx.fillStyle = '#9a9080';
        ctx.beginPath(); ctx.ellipse(cx, cy + sh * 0.1, r, r * 0.28, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#b0a890';
        ctx.fillRect(cx - r, sy + sh * 0.2, r * 2, sh * 0.52);
        for (let i = 0; i < 3; i++) {
            ctx.strokeStyle = '#7a7060'; ctx.lineWidth = 1;
            ctx.beginPath(); ctx.ellipse(cx, sy + sh * (0.28 + i * 0.14), r, r * 0.27, 0, 0, Math.PI * 2); ctx.stroke();
        }
        ctx.fillStyle = '#1a4a6a';
        ctx.beginPath(); ctx.ellipse(cx, sy + sh * 0.22, r * 0.78, r * 0.22, 0, 0, Math.PI * 2); ctx.fill();
        const rr = Math.max(1.5, sw * 0.06);
        ctx.strokeStyle = '#8a5020'; ctx.lineWidth = rr;
        for (const px of [cx - r * 0.8, cx + r * 0.8]) {
            ctx.beginPath(); ctx.moveTo(px, sy + sh * 0.2); ctx.lineTo(px, sy - sh * 0.1); ctx.stroke();
        }
        ctx.beginPath(); ctx.moveTo(cx - r * 0.8, sy - sh * 0.1); ctx.lineTo(cx + r * 0.8, sy - sh * 0.1); ctx.stroke();
        ctx.fillStyle = '#6a3810';
        ctx.beginPath(); ctx.moveTo(cx - r * 1.06, sy - sh * 0.1); ctx.lineTo(cx, sy - sh * 0.32); ctx.lineTo(cx + r * 1.06, sy - sh * 0.1); ctx.closePath(); ctx.fill();
        ctx.strokeStyle = '#c0a060'; ctx.lineWidth = 1;
        ctx.beginPath(); ctx.moveTo(cx, sy - sh * 0.08); ctx.lineTo(cx, sy + sh * 0.18); ctx.stroke();
        ctx.fillStyle = '#8a5030';
        ctx.fillRect(cx - sw * 0.1, sy + sh * 0.15, sw * 0.2, sh * 0.1);
    }

    _bldGarden(ctx, sx, sy, sw, sh) {
        ctx.fillStyle = '#68b468';
        ctx.beginPath(); ctx.ellipse(sx + sw / 2, sy + sh / 2, sw * 0.49, sh * 0.49, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#c8b870';
        ctx.fillRect(sx + sw * 0.44, sy + sh * 0.05, sw * 0.12, sh * 0.9);
        ctx.fillRect(sx + sw * 0.05, sy + sh * 0.44, sw * 0.9, sh * 0.12);
        const fc = ['#e84040','#e8c040','#e040e8','#40a8e8'];
        const qd = [{qx:0.16,qy:0.16},{qx:0.62,qy:0.16},{qx:0.16,qy:0.62},{qx:0.62,qy:0.62}];
        for (let i = 0; i < 4; i++) {
            const qx = sx + sw * qd[i].qx, qy = sy + sh * qd[i].qy;
            ctx.fillStyle = '#3a8a3a';
            ctx.beginPath(); ctx.arc(qx + sw * 0.12, qy + sh * 0.12, sw * 0.11, 0, Math.PI * 2); ctx.fill();
            for (let f = 0; f < 3; f++) {
                ctx.fillStyle = fc[(i + f) % fc.length];
                ctx.beginPath();
                ctx.arc(qx + sw * (0.04 + f * 0.1), qy + sh * (0.04 + f * 0.08), sw * 0.04, 0, Math.PI * 2);
                ctx.fill();
            }
        }
        ctx.fillStyle = '#1a7a1a';
        ctx.beginPath(); ctx.arc(sx + sw / 2, sy + sh / 2, sw * 0.1, 0, Math.PI * 2); ctx.fill();
        ctx.strokeStyle = '#a07040'; ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.ellipse(sx + sw / 2, sy + sh / 2, sw * 0.49, sh * 0.49, 0, 0, Math.PI * 2); ctx.stroke();
    }

    _bldGeneric(ctx, b, sx, sy, sw, sh) {
        ctx.fillStyle = b.def.color;
        ctx.fillRect(sx, sy, sw, sh);
        ctx.fillStyle = lighten(b.def.color, 30);
        ctx.fillRect(sx, sy, sw, sh * 0.22);
        ctx.strokeStyle = b.def.borderColor; ctx.lineWidth = 1.5;
        ctx.strokeRect(sx, sy, sw, sh);
        ctx.font = `${Math.min(sw * 0.55, sh * 0.55, 26)}px serif`;
        ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
        ctx.fillStyle = '#fff';
        ctx.fillText(b.def.emoji, sx + sw / 2, sy + sh / 2);
    }

    _drawUnderConstruction(ctx, sx, sy, sw, sh, b) {
        ctx.fillStyle = 'rgba(200,160,80,0.35)';
        ctx.fillRect(sx, sy, sw, sh);
        ctx.strokeStyle = '#8a6020'; ctx.lineWidth = Math.max(1, sw * 0.04);
        for (let i = 0; i <= 3; i++) {
            const px = sx + (sw / 3) * i;
            ctx.beginPath(); ctx.moveTo(px, sy); ctx.lineTo(px, sy + sh); ctx.stroke();
        }
        for (let i = 0; i <= 3; i++) {
            const py = sy + (sh / 3) * i;
            ctx.beginPath(); ctx.moveTo(sx, py); ctx.lineTo(sx + sw, py); ctx.stroke();
        }
        ctx.strokeStyle = '#a07830'; ctx.lineWidth = Math.max(0.5, sw * 0.02);
        for (let c = 0; c < 3; c++) for (let r = 0; r < 3; r++) {
            ctx.beginPath();
            ctx.moveTo(sx + (sw/3)*c, sy + (sh/3)*r);
            ctx.lineTo(sx + (sw/3)*(c+1), sy + (sh/3)*(r+1));
            ctx.stroke();
        }
        ctx.fillStyle = 'rgba(0,0,0,0.55)';
        ctx.fillRect(sx + sw * 0.1, sy + sh - 10 * this.zoom, sw * 0.8, 8 * this.zoom);
        ctx.fillStyle = '#f0a030';
        ctx.fillRect(sx + sw * 0.1, sy + sh - 10 * this.zoom, sw * 0.8 * (b.buildProgress / 100), 8 * this.zoom);
        if (this.zoom > 0.55) {
            ctx.font = `bold ${Math.max(7, 9 * this.zoom)}px sans-serif`;
            ctx.fillStyle = '#ffe080'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
            ctx.fillText(b.def.name, sx + sw / 2, sy + sh * 0.42);
            ctx.fillStyle = '#fff'; ctx.textBaseline = 'bottom';
            ctx.fillText(`${Math.floor(b.buildProgress)}%`, sx + sw / 2, sy + sh - 12 * this.zoom);
        }
    }

    /* ── Residents – medieval human silhouettes ─────────────────────────── */

    _drawResidents(residents, time) {
        if (this.zoom < 0.35) return;
        const ctx = this.ctx;
        for (const r of residents) {
            if (!r.alive) continue;
            const { x: sx, y: sy } = this.worldToScreen(r.x, r.y);
            if (sx < -30 || sx > this.canvas.width + 30 ||
                sy < -30 || sy > this.canvas.height + 30) continue;
            const scale = Math.max(0.38, this.zoom * 0.9);
            const bob   = Math.sin(r.animTimer * 1.5) * 1.2 * scale;
            ctx.save();
            ctx.translate(sx, sy - bob);
            this._drawPerson(ctx, r, scale);
            if (this.zoom > 1.5 && r.firstName) {
                const first = r.firstName;
                ctx.font = `${Math.max(6, 7 * this.zoom)}px sans-serif`;
                ctx.textAlign = 'center'; ctx.textBaseline = 'bottom';
                const tw = ctx.measureText(first).width;
                ctx.fillStyle = 'rgba(0,0,0,0.6)';
                ctx.fillRect(-tw / 2 - 2, -22 * scale - 11, tw + 4, 11);
                ctx.fillStyle = '#fff';
                ctx.fillText(first, 0, -22 * scale - 1);
            }
            if (r.thought && r._thoughtTimer > 0 && this.zoom > 1.1) {
                ctx.font = '9px sans-serif';
                const tw = ctx.measureText(r.thought).width + 10;
                const bx = -tw / 2, by = -30 * scale - 16;
                ctx.fillStyle = 'rgba(255,255,255,0.92)'; ctx.strokeStyle = '#aaa'; ctx.lineWidth = 1;
                if (ctx.roundRect) { ctx.beginPath(); ctx.roundRect(bx, by, tw, 14, 3); ctx.fill(); ctx.stroke(); }
                else { ctx.fillRect(bx, by, tw, 14); ctx.strokeRect(bx, by, tw, 14); }
                ctx.fillStyle = '#333'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
                ctx.fillText(r.thought, 0, by + 7);
            }
            ctx.restore();
        }
    }

    _drawPerson(ctx, r, s) {
        const career  = r.career || 'idle';
        const palette = PERSON_PALETTE[career] || PERSON_PALETTE.idle;

        // Shadow
        ctx.fillStyle = 'rgba(0,0,0,0.18)';
        ctx.beginPath(); ctx.ellipse(0, 8 * s, 5 * s, 1.8 * s, 0, 0, Math.PI * 2); ctx.fill();

        const swing = Math.sin(r.animTimer * 2) * 3 * s;

        // Legs
        for (const [lx, lswing] of [[-3 * s, swing], [3 * s, -swing]]) {
            ctx.save(); ctx.translate(lx, 4 * s); ctx.rotate(lswing * 0.1);
            ctx.fillStyle = darken(palette.body, 20);
            ctx.fillRect(-2 * s, 0, 4 * s, 7 * s);
            ctx.fillStyle = '#3a2010';
            ctx.fillRect(-2.5 * s, 6 * s, 5 * s, 2.5 * s);
            ctx.restore();
        }

        // Torso
        ctx.fillStyle = palette.body;
        ctx.beginPath();
        ctx.moveTo(-5 * s, -8 * s);
        ctx.lineTo(-6 * s,  4 * s);
        ctx.lineTo( 6 * s,  4 * s);
        ctx.lineTo( 5 * s, -8 * s);
        ctx.closePath();
        ctx.fill();
        // Belt
        ctx.fillStyle = '#4a2810'; ctx.fillRect(-6 * s, 1 * s, 12 * s, 2 * s);
        ctx.fillStyle = '#c0a030'; ctx.fillRect(-1.5 * s, 0.5 * s, 3 * s, 3 * s);

        // Arms
        for (const [ax, aswing] of [[-6.5 * s, -swing], [6.5 * s, swing]]) {
            ctx.save(); ctx.translate(ax, -6 * s); ctx.rotate(aswing * 0.12);
            ctx.fillStyle = palette.body; ctx.fillRect(-2 * s, 0, 4 * s, 9 * s);
            ctx.fillStyle = palette.skin; ctx.fillRect(-1.5 * s, 8 * s, 3 * s, 3 * s);
            ctx.restore();
        }

        // Neck + head
        ctx.fillStyle = palette.skin;
        ctx.fillRect(-2 * s, -11 * s, 4 * s, 4 * s);
        ctx.beginPath(); ctx.ellipse(0, -15 * s, 5 * s, 6 * s, 0, 0, Math.PI * 2); ctx.fill();

        // Hair
        ctx.fillStyle = palette.hair;
        ctx.beginPath(); ctx.ellipse(0, -19 * s, 5 * s, 3 * s, 0, 0, Math.PI); ctx.fill();

        // Eyes
        ctx.fillStyle = '#1a1010';
        ctx.beginPath(); ctx.ellipse(-2 * s, -15.5 * s, 1 * s, 1.2 * s, 0, 0, Math.PI * 2); ctx.fill();
        ctx.beginPath(); ctx.ellipse( 2 * s, -15.5 * s, 1 * s, 1.2 * s, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = 'rgba(255,255,255,0.7)';
        ctx.beginPath(); ctx.arc(-1.5 * s, -16 * s, 0.45 * s, 0, Math.PI * 2); ctx.fill();
        ctx.beginPath(); ctx.arc( 2.5 * s, -16 * s, 0.45 * s, 0, Math.PI * 2); ctx.fill();

        // Mouth (happy/sad)
        const happy = (r.happiness || 60) > 50;
        ctx.strokeStyle = '#5a2010'; ctx.lineWidth = Math.max(0.5, s * 0.7);
        ctx.beginPath();
        if (happy) ctx.arc(0, -13.5 * s, 2.5 * s, 0.1, Math.PI - 0.1);
        else        ctx.arc(0, -12 * s, 2.5 * s, Math.PI + 0.1, -0.1);
        ctx.stroke();

        // Career hat
        this._drawCareerHat(ctx, career, s, palette.hat);

        // Tool
        if (this.zoom > 0.75) this._drawCareerTool(ctx, career, s);
    }

    _drawCareerHat(ctx, career, s, hatColor) {
        ctx.fillStyle = hatColor || '#6a4020';
        switch (career) {
            case 'farmer': case 'hunter':
                ctx.fillStyle = '#c8a840';
                ctx.beginPath(); ctx.ellipse(0, -19 * s, 8 * s, 2 * s, 0, 0, Math.PI * 2); ctx.fill();
                ctx.fillStyle = '#b89830';
                ctx.beginPath(); ctx.ellipse(0, -21 * s, 5 * s, 2.5 * s, 0, 0, Math.PI * 2); ctx.fill();
                break;
            case 'smith': case 'logger': case 'miner':
                ctx.fillStyle = '#5a3820';
                ctx.beginPath(); ctx.ellipse(0, -19 * s, 5.5 * s, 2 * s, 0, 0, Math.PI * 2); ctx.fill();
                ctx.fillRect(-5 * s, -24 * s, 10 * s, 6 * s);
                ctx.fillStyle = '#4a2810';
                ctx.fillRect(-5.5 * s, -19 * s, 11 * s, 2 * s);
                break;
            case 'noble':
                ctx.fillStyle = '#8a2020';
                ctx.beginPath(); ctx.moveTo(-4.5*s,-21*s); ctx.lineTo(-3*s,-31*s); ctx.lineTo(3*s,-31*s); ctx.lineTo(4.5*s,-21*s); ctx.closePath(); ctx.fill();
                ctx.fillStyle = '#c04040'; ctx.fillRect(-5 * s, -22 * s, 10 * s, 2 * s);
                break;
            case 'priest':
                ctx.fillStyle = '#ece8dc';
                ctx.beginPath(); ctx.moveTo(-4.5*s,-21*s); ctx.lineTo(-3*s,-31*s); ctx.lineTo(3*s,-31*s); ctx.lineTo(4.5*s,-21*s); ctx.closePath(); ctx.fill();
                ctx.fillStyle = '#d4c880'; ctx.fillRect(-5 * s, -22 * s, 10 * s, 2 * s);
                break;
            case 'scholar':
                ctx.fillStyle = '#1a1a2a';
                ctx.fillRect(-5 * s, -22 * s, 10 * s, 3 * s);
                ctx.beginPath(); ctx.moveTo(-7*s,-22*s); ctx.lineTo(7*s,-22*s); ctx.lineTo(0,-25*s); ctx.closePath(); ctx.fill();
                break;
            case 'trader': case 'innkeeper':
                ctx.fillStyle = '#8a4030';
                ctx.beginPath(); ctx.ellipse(1 * s, -20 * s, 6 * s, 3 * s, -0.3, 0, Math.PI * 2); ctx.fill();
                ctx.fillStyle = '#7a3020';
                ctx.beginPath(); ctx.ellipse(0, -19 * s, 5 * s, 1.5 * s, 0, 0, Math.PI * 2); ctx.fill();
                break;
            case 'fisher':
                ctx.fillStyle = '#607090';
                ctx.beginPath(); ctx.ellipse(0, -19 * s, 7 * s, 2 * s, -0.15, 0, Math.PI * 2); ctx.fill();
                ctx.fillStyle = '#506080';
                ctx.beginPath(); ctx.ellipse(0, -21 * s, 5 * s, 3 * s, 0, 0, Math.PI); ctx.fill();
                break;
            default:
                ctx.beginPath(); ctx.ellipse(0, -19 * s, 5 * s, 2 * s, 0, 0, Math.PI * 2); ctx.fill();
                ctx.beginPath(); ctx.ellipse(0, -21 * s, 4 * s, 3 * s, 0, 0, Math.PI); ctx.fill();
                break;
        }
    }

    _drawCareerTool(ctx, career, s) {
        ctx.strokeStyle = '#5a3010'; ctx.lineWidth = Math.max(0.8, s * 0.8);
        switch (career) {
            case 'farmer':
                ctx.beginPath(); ctx.moveTo(7*s,-4*s); ctx.lineTo(10*s,8*s); ctx.stroke();
                ctx.strokeStyle = '#6a4020';
                ctx.beginPath(); ctx.moveTo(7*s,-4*s); ctx.lineTo(13*s,-2*s); ctx.stroke();
                break;
            case 'smith':
                ctx.strokeStyle = '#808080'; ctx.lineWidth = s * 1.2;
                ctx.beginPath(); ctx.moveTo(8*s,-2*s); ctx.lineTo(8*s,8*s); ctx.stroke();
                ctx.fillStyle = '#707070'; ctx.fillRect(6*s,-5*s,5*s,4*s);
                break;
            case 'logger':
                ctx.beginPath(); ctx.moveTo(8*s,-3*s); ctx.lineTo(8*s,8*s); ctx.stroke();
                ctx.fillStyle = '#909090';
                ctx.beginPath(); ctx.moveTo(7*s,-4*s); ctx.lineTo(12*s,-2*s); ctx.lineTo(10*s,2*s); ctx.closePath(); ctx.fill();
                break;
            case 'hunter':
                ctx.strokeStyle = '#8a5020'; ctx.lineWidth = s * 0.9;
                ctx.beginPath(); ctx.arc(10*s, 0, 5*s, -1.2, 1.2); ctx.stroke();
                ctx.strokeStyle = '#d0c080'; ctx.lineWidth = s * 0.4;
                ctx.beginPath(); ctx.moveTo(10*s,-5*s*Math.sin(1.2)); ctx.lineTo(10*s,5*s*Math.sin(1.2)); ctx.stroke();
                break;
            case 'miner':
                ctx.beginPath(); ctx.moveTo(6*s,-3*s); ctx.lineTo(8*s,8*s); ctx.stroke();
                ctx.fillStyle = '#a09080';
                ctx.beginPath(); ctx.moveTo(4*s,-5*s); ctx.lineTo(12*s,-4*s); ctx.lineTo(8*s,0); ctx.closePath(); ctx.fill();
                break;
            case 'fisher':
                ctx.strokeStyle = '#8a5020';
                ctx.beginPath(); ctx.moveTo(7*s,-8*s); ctx.lineTo(12*s,4*s); ctx.stroke();
                ctx.strokeStyle = '#d0d0c0'; ctx.lineWidth = s * 0.4;
                ctx.beginPath(); ctx.moveTo(12*s,4*s); ctx.lineTo(14*s,12*s); ctx.stroke();
                break;
        }
    }

    /* ── Ghost preview ───────────────────────────────────────────────────── */

    drawGhost(type, wx, wy, canPlace) {
        const def = BUILDING_DEFS[type];
        if (!def) return;
        const { x: sx, y: sy } = this.worldToScreen(wx, wy);
        const sw = def.size.w * this.zoom;
        const sh = def.size.h * this.zoom;
        this.ctx.globalAlpha = 0.55;
        this.ctx.save();
        this._drawBuildingShape(this.ctx, { type, def, animOffset: 0 }, sx, sy, sw, sh, 0);
        this.ctx.restore();
        this.ctx.globalAlpha = 1;
        this.ctx.strokeStyle = canPlace ? '#88ff88' : '#ff4444';
        this.ctx.lineWidth   = 2.5;
        this.ctx.setLineDash(canPlace ? [] : [6, 4]);
        this.ctx.strokeRect(sx, sy, sw, sh);
        this.ctx.setLineDash([]);
    }

    /* ── Road preview ────────────────────────────────────────────────────── */

    drawRoadPreview(points) {
        if (points.length < 2) return;
        const ctx = this.ctx;
        ctx.save();
        ctx.strokeStyle = 'rgba(200,168,112,0.7)';
        ctx.lineWidth   = Math.max(2, 4 * this.zoom);
        ctx.setLineDash([8, 5]);
        ctx.lineCap = 'round';
        const p0 = this.worldToScreen(points[0].x, points[0].y);
        ctx.beginPath(); ctx.moveTo(p0.x, p0.y);
        for (let i = 1; i < points.length; i++) {
            const p = this.worldToScreen(points[i].x, points[i].y);
            ctx.lineTo(p.x, p.y);
        }
        ctx.stroke(); ctx.setLineDash([]); ctx.restore();
    }

    /* ── Main render ─────────────────────────────────────────────────────── */

    render(state, time) {
        const { ctx, canvas } = this;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        this._drawTerrain();
        this._drawRoads(state.roads);
        this._drawBuildings(state.buildings, state.selectedBuildingId, time);
        this._drawResidents(state.residents, time);
        if (state.ghost) this.drawGhost(state.ghost.type, state.ghost.wx, state.ghost.wy, state.ghost.canPlace);
        if (state.roadPreview && state.roadPreview.length > 0) this.drawRoadPreview(state.roadPreview);
        if (this.world.season === 'winter') {
            ctx.fillStyle = 'rgba(200,220,255,0.07)'; ctx.fillRect(0, 0, canvas.width, canvas.height);
        } else if (this.world.season === 'autumn') {
            ctx.fillStyle = 'rgba(255,180,80,0.04)'; ctx.fillRect(0, 0, canvas.width, canvas.height);
        }
    }

    invalidateTerrain() { this._terrainDirty = true; }
}

/* ── Per-career person colour palettes ─────────────────────────────────────── */
const PERSON_PALETTE = {
    idle:      { body: '#a08060', skin: '#e8c090', hair: '#5a3820', hat: '#806040' },
    farmer:    { body: '#7a9a50', skin: '#d8b070', hair: '#4a3010', hat: '#c8a840' },
    hunter:    { body: '#6a7840', skin: '#d0a060', hair: '#3a2810', hat: '#c8a840' },
    fisher:    { body: '#6080a0', skin: '#d8b880', hair: '#4a3820', hat: '#607090' },
    logger:    { body: '#8a5030', skin: '#d8a870', hair: '#3a2010', hat: '#5a3820' },
    miner:     { body: '#706860', skin: '#c8a878', hair: '#3a3030', hat: '#5a3820' },
    smith:     { body: '#585050', skin: '#c89878', hair: '#2a2020', hat: '#5a3820' },
    trader:    { body: '#c0901a', skin: '#e8c090', hair: '#5a3010', hat: '#8a4030' },
    innkeeper: { body: '#c07828', skin: '#e0b880', hair: '#4a3020', hat: '#8a4030' },
    builder:   { body: '#d0a040', skin: '#d8b070', hair: '#4a3020', hat: '#806040' },
    scholar:   { body: '#2a3888', skin: '#e0c898', hair: '#2a2020', hat: '#1a1a2a' },
    noble:     { body: '#801820', skin: '#f0d0a0', hair: '#1a1010', hat: '#8a2020' },
    priest:    { body: '#e8e4d8', skin: '#e8c898', hair: '#3a2820', hat: '#ece8dc' },
};
