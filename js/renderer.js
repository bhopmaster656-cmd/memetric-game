/**
 * Canvas 2D renderer – world, buildings, roads, residents.
 */

class Renderer {
    constructor(canvas, world) {
        this.canvas  = canvas;
        this.ctx     = canvas.getContext('2d');
        this.world   = world;

        // Camera
        this.camX    = 0;
        this.camY    = 0;
        this.zoom    = 1;
        this.minZoom = 0.3;
        this.maxZoom = 3.0;

        // Tile cache (one OffscreenCanvas per zoom band)
        this._terrainCache = null;
        this._terrainDirty = true;

        this.resize();
    }

    resize() {
        this.canvas.width  = window.innerWidth;
        this.canvas.height = window.innerHeight;
        this._terrainDirty = true;
    }

    /* ── Camera helpers ─────────────────────────────────────────────────── */

    /** Screen pixel → world pixel */
    screenToWorld(sx, sy) {
        return {
            x: (sx - this.canvas.width  / 2) / this.zoom + this.camX,
            y: (sy - this.canvas.height / 2) / this.zoom + this.camY,
        };
    }

    /** World pixel → screen pixel */
    worldToScreen(wx, wy) {
        return {
            x: (wx - this.camX) * this.zoom + this.canvas.width  / 2,
            y: (wy - this.camY) * this.zoom + this.canvas.height / 2,
        };
    }

    centerOn(wx, wy) {
        this.camX = wx;
        this.camY = wy;
    }

    pan(dx, dy) {
        this.camX -= dx / this.zoom;
        this.camY -= dy / this.zoom;
        this._clampCamera();
    }

    zoomAt(sx, sy, factor) {
        const wBefore = this.screenToWorld(sx, sy);
        this.zoom = clamp(this.zoom * factor, this.minZoom, this.maxZoom);
        const wAfter  = this.screenToWorld(sx, sy);
        this.camX += wBefore.x - wAfter.x;
        this.camY += wBefore.y - wAfter.y;
        this._clampCamera();
        this._terrainDirty = true;
    }

    _clampCamera() {
        const hw = this.canvas.width  / 2 / this.zoom;
        const hh = this.canvas.height / 2 / this.zoom;
        this.camX = clamp(this.camX, hw, this.world.width  - hw);
        this.camY = clamp(this.camY, hh, this.world.height - hh);
    }

    /* ── Terrain ────────────────────────────────────────────────────────── */

    _buildTerrainCache() {
        const { cols, rows, tileSize } = this.world;
        const w = cols * tileSize;
        const h = rows * tileSize;
        const off = document.createElement('canvas');
        off.width  = w;
        off.height = h;
        const ctx  = off.getContext('2d');
        const ts   = tileSize;

        for (let row = 0; row < rows; row++) {
            for (let col = 0; col < cols; col++) {
                const type = this.world.getTile(col, row);
                ctx.fillStyle = this.world.tileColor(type);
                ctx.fillRect(col * ts, row * ts, ts, ts);

                // Forest trees
                if (type === TERRAIN.FOREST) {
                    ctx.fillStyle = 'rgba(0,50,0,0.35)';
                    const cx = col * ts + ts / 2, cy = row * ts + ts / 2;
                    ctx.beginPath();
                    ctx.arc(cx, cy, ts * 0.38, 0, Math.PI * 2);
                    ctx.fill();
                }

                // Water sheen
                if (type === TERRAIN.WATER || type === TERRAIN.DEEP_WATER) {
                    ctx.fillStyle = 'rgba(255,255,255,0.06)';
                    ctx.fillRect(col * ts, row * ts, ts, ts / 3);
                }

                // Subtle grid
                ctx.strokeStyle = 'rgba(0,0,0,0.04)';
                ctx.lineWidth = 0.5;
                ctx.strokeRect(col * ts, row * ts, ts, ts);
            }
        }
        this._terrainCache  = off;
        this._terrainDirty  = false;
    }

    _drawTerrain() {
        if (this._terrainDirty) this._buildTerrainCache();
        const { x: sx, y: sy } = this.worldToScreen(0, 0);
        const scale = this.zoom;
        this.ctx.drawImage(
            this._terrainCache,
            sx, sy,
            this.world.cols * this.world.tileSize * scale,
            this.world.rows * this.world.tileSize * scale,
        );
    }

    /* ── Roads ──────────────────────────────────────────────────────────── */

    _drawRoads(roads) {
        const ctx = this.ctx;
        ctx.save();
        ctx.strokeStyle = '#c8a870';
        ctx.lineWidth   = Math.max(2, 4 * this.zoom);
        ctx.lineCap     = 'round';
        ctx.lineJoin    = 'round';

        for (const road of roads) {
            if (road.points.length < 2) continue;
            const p0 = this.worldToScreen(road.points[0].x, road.points[0].y);
            ctx.beginPath();
            ctx.moveTo(p0.x, p0.y);
            for (let i = 1; i < road.points.length; i++) {
                const p = this.worldToScreen(road.points[i].x, road.points[i].y);
                ctx.lineTo(p.x, p.y);
            }
            ctx.stroke();
        }
        ctx.restore();
    }

    /* ── Buildings ──────────────────────────────────────────────────────── */

    _drawBuildings(buildings, selectedId, time) {
        const ctx = this.ctx;
        for (const b of buildings) {
            const { x: sx, y: sy } = this.worldToScreen(b.x, b.y);
            const sw = b.w * this.zoom;
            const sh = b.h * this.zoom;

            if (sx + sw < 0 || sx > this.canvas.width  ||
                sy + sh < 0 || sy > this.canvas.height) continue; // frustum cull

            // Under construction – hatched
            if (!b.constructed) {
                this._drawUnderConstruction(ctx, sx, sy, sw, sh, b);
                continue;
            }

            // Shadow
            ctx.fillStyle = 'rgba(0,0,0,0.18)';
            ctx.fillRect(sx + sw * 0.05, sy + sh * 0.06, sw, sh);

            // Main body
            ctx.fillStyle = b.def.color;
            ctx.fillRect(sx, sy, sw, sh);

            // Roof highlight (top strip)
            ctx.fillStyle = lighten(b.def.color, 30);
            ctx.fillRect(sx, sy, sw, sh * 0.22);

            // Border / stroke
            ctx.strokeStyle = b.id === selectedId ? '#ffee44' : b.def.borderColor;
            ctx.lineWidth   = b.id === selectedId ? 3 : 1.5;
            ctx.strokeRect(sx, sy, sw, sh);

            // Emoji icon
            if (this.zoom > 0.5) {
                const fs = Math.max(10, Math.min(sw * 0.55, sh * 0.55, 28));
                ctx.font      = `${fs}px serif`;
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                ctx.fillText(b.def.emoji, sx + sw / 2, sy + sh / 2);
            }

            // Name label
            if (this.zoom > 0.9) {
                ctx.font      = `bold ${Math.max(8, 9 * this.zoom)}px sans-serif`;
                ctx.fillStyle = '#fff';
                ctx.strokeStyle = '#0007';
                ctx.lineWidth = 2;
                ctx.textAlign = 'center';
                ctx.textBaseline = 'bottom';
                ctx.strokeText(b.def.name, sx + sw / 2, sy - 2);
                ctx.fillText  (b.def.name, sx + sw / 2, sy - 2);
            }

            // Happiness sparkle for civic buildings
            if (b.def.happinessBonus && this.zoom > 0.7) {
                const t = time * 0.001 + b.animOffset;
                const px2 = sx + sw - 5;
                const py2 = sy + 5;
                ctx.font = `${Math.max(8, 10 * this.zoom)}px serif`;
                ctx.textAlign = 'left';
                ctx.textBaseline = 'top';
                ctx.globalAlpha = 0.5 + 0.5 * Math.sin(t * 3);
                ctx.fillText('✨', px2, py2);
                ctx.globalAlpha = 1;
            }

            // Worker badge
            if (b.def.maxWorkers && this.zoom > 0.6) {
                const fill = b.workerCount >= b.maxWorkers ? '#4aaa44' : '#e88830';
                ctx.fillStyle   = fill;
                ctx.strokeStyle = '#222';
                ctx.lineWidth   = 1;
                ctx.beginPath();
                ctx.arc(sx + sw - 8, sy + sh - 8, 6 * this.zoom, 0, Math.PI * 2);
                ctx.fill();
                ctx.stroke();
                ctx.font      = `bold ${Math.max(7, 7 * this.zoom)}px sans-serif`;
                ctx.fillStyle = '#fff';
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                ctx.fillText(`${b.workerCount}/${b.maxWorkers}`, sx + sw - 8, sy + sh - 8);
            }
        }
    }

    _drawUnderConstruction(ctx, sx, sy, sw, sh, b) {
        ctx.fillStyle   = 'rgba(200,160,80,0.4)';
        ctx.fillRect(sx, sy, sw, sh);
        ctx.strokeStyle = '#c8a870';
        ctx.lineWidth   = 1.5;
        ctx.setLineDash([6, 4]);
        ctx.strokeRect(sx, sy, sw, sh);
        ctx.setLineDash([]);

        // Progress bar
        ctx.fillStyle = 'rgba(0,0,0,0.5)';
        ctx.fillRect(sx, sy + sh - 8 * this.zoom, sw, 8 * this.zoom);
        ctx.fillStyle = '#f0a030';
        ctx.fillRect(sx, sy + sh - 8 * this.zoom, sw * (b.buildProgress / 100), 8 * this.zoom);

        if (this.zoom > 0.5) {
            ctx.font      = `${Math.max(10, 14 * this.zoom)}px serif`;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText('🏗️', sx + sw / 2, sy + sh / 2 - 4);
        }
    }

    /* ── Residents ──────────────────────────────────────────────────────── */

    _drawResidents(residents, time) {
        if (this.zoom < 0.4) return;   // don't draw tiny dots
        const ctx = this.ctx;

        for (const r of residents) {
            if (!r.alive) continue;
            const { x: sx, y: sy } = this.worldToScreen(r.x, r.y);
            if (sx < -20 || sx > this.canvas.width  + 20 ||
                sy < -20 || sy > this.canvas.height + 20) continue;

            const radius = Math.max(3, 5 * this.zoom);
            const bob    = Math.sin(r.animTimer) * 1.5 * this.zoom;

            // Shadow
            ctx.fillStyle = 'rgba(0,0,0,0.2)';
            ctx.beginPath();
            ctx.ellipse(sx, sy + radius, radius * 0.8, radius * 0.25, 0, 0, Math.PI * 2);
            ctx.fill();

            // Body circle
            ctx.fillStyle = r.color;
            ctx.strokeStyle = darken(r.color, 30);
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.arc(sx, sy - bob, radius, 0, Math.PI * 2);
            ctx.fill();
            ctx.stroke();

            // Face dot
            ctx.fillStyle = '#fff';
            ctx.beginPath();
            ctx.arc(sx - radius * 0.2, sy - bob - radius * 0.2, radius * 0.2, 0, Math.PI * 2);
            ctx.fill();
            ctx.beginPath();
            ctx.arc(sx + radius * 0.2, sy - bob - radius * 0.2, radius * 0.2, 0, Math.PI * 2);
            ctx.fill();

            // Thought bubble
            if (r.thought && r._thoughtTimer > 0 && this.zoom > 1.0) {
                ctx.font      = '10px sans-serif';
                ctx.fillStyle = 'rgba(255,255,255,0.9)';
                ctx.strokeStyle = '#888';
                ctx.lineWidth = 1;
                const tw = ctx.measureText(r.thought).width + 8;
                // Draw thought bubble
                const bx = sx - tw / 2, by = sy - radius * 2 - 20;
                const br = 4;
                ctx.beginPath();
                if (ctx.roundRect) {
                    ctx.roundRect(bx, by, tw, 16, br);
                } else {
                    ctx.rect(bx, by, tw, 16);
                }
                ctx.fill();
                ctx.stroke();
                ctx.fillStyle = '#333';
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                ctx.fillText(r.thought, sx, sy - radius * 2 - 12);
            }
        }
    }

    /* ── Ghost building (placement preview) ────────────────────────────── */

    drawGhost(type, wx, wy, canPlace) {
        const def = BUILDING_DEFS[type];
        if (!def) return;
        const { x: sx, y: sy } = this.worldToScreen(wx, wy);
        const sw = def.size.w * this.zoom;
        const sh = def.size.h * this.zoom;
        this.ctx.globalAlpha = 0.6;
        this.ctx.fillStyle   = canPlace ? def.color : '#dd4444';
        this.ctx.fillRect(sx, sy, sw, sh);
        this.ctx.strokeStyle = canPlace ? '#88ff88' : '#ff4444';
        this.ctx.lineWidth   = 2;
        this.ctx.strokeRect(sx, sy, sw, sh);
        this.ctx.font        = `${Math.min(sw * 0.6, sh * 0.6, 30)}px serif`;
        this.ctx.textAlign   = 'center';
        this.ctx.textBaseline = 'middle';
        this.ctx.fillStyle   = '#fff';
        this.ctx.fillText(def.emoji, sx + sw / 2, sy + sh / 2);
        this.ctx.globalAlpha = 1;
    }

    /* ── Road drawing preview ────────────────────────────────────────────── */

    drawRoadPreview(points) {
        if (points.length < 2) return;
        const ctx = this.ctx;
        ctx.save();
        ctx.strokeStyle = 'rgba(200,168,112,0.7)';
        ctx.lineWidth   = Math.max(2, 4 * this.zoom);
        ctx.setLineDash([8, 5]);
        ctx.lineCap     = 'round';
        const p0 = this.worldToScreen(points[0].x, points[0].y);
        ctx.beginPath();
        ctx.moveTo(p0.x, p0.y);
        for (let i = 1; i < points.length; i++) {
            const p = this.worldToScreen(points[i].x, points[i].y);
            ctx.lineTo(p.x, p.y);
        }
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.restore();
    }

    /* ── Main render ─────────────────────────────────────────────────────── */

    render(state, time) {
        const { ctx, canvas } = this;
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Terrain
        this._drawTerrain();

        // Roads
        this._drawRoads(state.roads);

        // Buildings
        this._drawBuildings(state.buildings, state.selectedBuildingId, time);

        // Residents
        this._drawResidents(state.residents, time);

        // Ghost
        if (state.ghost) {
            const { type, wx, wy, canPlace } = state.ghost;
            this.drawGhost(type, wx, wy, canPlace);
        }

        // Road preview
        if (state.roadPreview && state.roadPreview.length > 0) {
            this.drawRoadPreview(state.roadPreview);
        }

        // Season overlay (very subtle)
        if (this.world.season === 'winter') {
            ctx.fillStyle = 'rgba(200,220,255,0.08)';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
        }
    }

    invalidateTerrain() { this._terrainDirty = true; }
}
