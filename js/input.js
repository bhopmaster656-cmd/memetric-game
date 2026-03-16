/**
 * Input handler – mouse, wheel, touch.
 * Modes: 'view' | 'place' | 'road' | 'demolish'
 */

class InputHandler {
    constructor(canvas, renderer, game) {
        this.canvas   = canvas;
        this.renderer = renderer;
        this.game     = game;

        this.mode      = 'view';
        this.placeType = null;

        // Pan state
        this._panning  = false;
        this._panStart = { x: 0, y: 0 };

        // Road drawing state
        this._roadPoints  = [];
        this._roadDrawing = false;

        // Last world cursor
        this.cursorWorld = { x: 0, y: 0 };

        this._bind();
    }

    setMode(mode, placeType) {
        this.mode      = mode;
        this.placeType = placeType || null;
        this._roadPoints  = [];
        this._roadDrawing = false;
        this.canvas.style.cursor = mode === 'demolish' ? 'crosshair' : 'default';

        // Update ghost
        if (mode !== 'place') this.game.ghost = null;
    }

    _bind() {
        const c = this.canvas;
        c.addEventListener('mousemove',  e => this._onMove(e));
        c.addEventListener('mousedown',  e => this._onDown(e));
        c.addEventListener('mouseup',    e => this._onUp(e));
        c.addEventListener('wheel',      e => this._onWheel(e), { passive: false });
        c.addEventListener('contextmenu', e => e.preventDefault());

        // Touch
        c.addEventListener('touchstart', e => this._onTouchStart(e), { passive: false });
        c.addEventListener('touchmove',  e => this._onTouchMove(e),  { passive: false });
        c.addEventListener('touchend',   e => this._onTouchEnd(e));
    }

    _screenToWorld(e) {
        const rect = this.canvas.getBoundingClientRect();
        const sx = (e.clientX || e.touches?.[0]?.clientX || 0) - rect.left;
        const sy = (e.clientY || e.touches?.[0]?.clientY || 0) - rect.top;
        return this.renderer.screenToWorld(sx, sy);
    }

    _onMove(e) {
        const w = this._screenToWorld(e);
        this.cursorWorld = w;

        // Pan
        if (this._panning) {
            const dx = e.clientX - this._panStart.x;
            const dy = e.clientY - this._panStart.y;
            this.renderer.pan(-dx, -dy);
            this._panStart = { x: e.clientX, y: e.clientY };
            return;
        }

        // Ghost update
        if (this.mode === 'place' && this.placeType) {
            const def = BUILDING_DEFS[this.placeType];
            const wx  = w.x - def.size.w / 2;
            const wy  = w.y - def.size.h / 2;
            const canP = this.game.buildingManager.canPlace(this.placeType, wx, wy) &&
                         this.game.world.isBuildable(wx, wy, def.size.w, def.size.h);
            this.game.ghost = { type: this.placeType, wx, wy, canPlace: canP };
        }

        // Road drawing
        if (this.mode === 'road' && this._roadDrawing) {
            if (this._roadPoints.length > 0) {
                const last = this._roadPoints[this._roadPoints.length - 1];
                if (dist(last.x, last.y, w.x, w.y) > 16) {
                    this._roadPoints.push({ x: w.x, y: w.y });
                }
                this.game.roadPreview = this._roadPoints.slice();
            }
        }
    }

    _onDown(e) {
        // Middle button or right button → pan
        if (e.button === 1 || e.button === 2) {
            this._panning = true;
            this._panStart = { x: e.clientX, y: e.clientY };
            return;
        }

        const w = this._screenToWorld(e);

        if (this.mode === 'view') {
            // Check click on building
            const b = this.game.buildingManager.getAt(w.x, w.y);
            if (b) {
                this.game.selectedBuildingId = b.id;
                this.game.ui.showBuildingInfo(b);
            } else {
                // Check click on resident
                const r = this._findResidentAt(w.x, w.y);
                if (r) {
                    this.game.ui.showResidentProfile(r);
                } else {
                    this.game.selectedBuildingId = null;
                    this.game.ui.hideBottomPanel();
                }
            }
            // Allow pan with left button when in view mode
            this._panning = true;
            this._panStart = { x: e.clientX, y: e.clientY };
            return;
        }

        if (this.mode === 'place' && this.placeType) {
            const def = BUILDING_DEFS[this.placeType];
            const wx  = w.x - def.size.w / 2;
            const wy  = w.y - def.size.h / 2;
            this.game.tryPlace(this.placeType, wx, wy);
            return;
        }

        if (this.mode === 'road') {
            this._roadDrawing = true;
            this._roadPoints  = [{ x: w.x, y: w.y }];
            return;
        }

        if (this.mode === 'demolish') {
            const b = this.game.buildingManager.getAt(w.x, w.y);
            if (b) this.game.demolish(b.id);
            return;
        }
    }

    _onUp(e) {
        if (this._panning) {
            this._panning = false;
            return;
        }

        if (this.mode === 'road' && this._roadDrawing) {
            this._roadDrawing = false;
            if (this._roadPoints.length >= 2) {
                this.game.addRoad(this._roadPoints);
            }
            this._roadPoints  = [];
            this.game.roadPreview = null;
        }
    }

    _onWheel(e) {
        e.preventDefault();
        const rect = this.canvas.getBoundingClientRect();
        const sx = e.clientX - rect.left;
        const sy = e.clientY - rect.top;
        const factor = e.deltaY < 0 ? 1.12 : 0.88;
        this.renderer.zoomAt(sx, sy, factor);
    }

    /* ── Touch support (pinch to zoom) ─────────────────────────────────── */

    _touch2Dist(e) {
        const dx = e.touches[0].clientX - e.touches[1].clientX;
        const dy = e.touches[0].clientY - e.touches[1].clientY;
        return Math.sqrt(dx * dx + dy * dy);
    }

    _onTouchStart(e) {
        e.preventDefault();
        if (e.touches.length === 2) {
            this._pinchDist = this._touch2Dist(e);
            return;
        }
        const fakeEvent = { clientX: e.touches[0].clientX, clientY: e.touches[0].clientY, button: 0 };
        this._onDown(fakeEvent);
    }

    _onTouchMove(e) {
        e.preventDefault();
        if (e.touches.length === 2) {
            const newDist = this._touch2Dist(e);
            const factor  = newDist / this._pinchDist;
            const cx = (e.touches[0].clientX + e.touches[1].clientX) / 2;
            const cy = (e.touches[0].clientY + e.touches[1].clientY) / 2;
            const rect = this.canvas.getBoundingClientRect();
            this.renderer.zoomAt(cx - rect.left, cy - rect.top, factor);
            this._pinchDist = newDist;
            return;
        }
        const fakeEvent = {
            clientX: e.touches[0].clientX, clientY: e.touches[0].clientY,
            touches: e.touches,
        };
        this._onMove(fakeEvent);
    }

    _onTouchEnd(e) {
        const fakeEvent = { button: 0 };
        this._onUp(fakeEvent);
    }

    _findResidentAt(wx, wy) {
        const threshold = 12 / this.renderer.zoom;
        for (const r of this.game.residentManager.alive()) {
            if (dist(r.x, r.y, wx, wy) < threshold) return r;
        }
        return null;
    }
}
