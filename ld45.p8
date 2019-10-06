pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
-- made with super-fast-framework

------------------------- start imports
function bbox(w,h,xoff1,yoff1,xoff2,yoff2)
    local bb ={
        offsets={ xoff1 or 0, yoff1 or 0, xoff2 or 0, yoff2 or 0},
        w=w,
        h=h,
    }
    bb.xoff1= bb.offsets[1]
    bb.yoff1= bb.offsets[2]
    bb.xoff2= bb.offsets[3]
    bb.yoff2= bb.offsets[4]
    function bb:setx(x)
        bb.xoff1=x+bb.offsets[1]
        bb.xoff2=x+bb.w-bb.offsets[3]
    end
    function bb:sety(y)
        bb.yoff1=y+bb.offsets[2]
        bb.yoff2=y+bb.h-bb.offsets[4]
    end
    function bb:printbounds()
        rect(bb.xoff1, bb.yoff1, bb.xoff2, bb.yoff2, 8)
    end
    return bb
end
function anim()
    local a={
        list={},
        current=nil,
        tick=0,
    }
    function a:_get_fr(one_shot, callback)
        local anim=a.current
        local aspeed,fq,st,step= anim.speed, anim.fr_cant, anim.first_fr, flr(a.tick)*anim.w
        a.tick+=aspeed
        local new_step=flr(flr(a.tick)*anim.w)
		if st+new_step >= st+(fq*anim.w) then
		    if one_shot then
		        a.tick-=aspeed
		        callback()
		    else
		        a.tick=0
		    end
		end
		return st+step
    end
    function a:set_anim(idx)
        if (a.currentidx == nil or idx ~= a.currentidx) a.tick=0 
        a.current=a.list[idx]
        a.currentidx=idx
    end
	function a:add(first_fr, fr_cant, speed, zoomw, zoomh, one_shot, callback)
		local an={
            first_fr=first_fr,
            fr_cant=fr_cant,
            speed=speed,
            w=zoomw,
            h=zoomh,
            callback=callback or function()end,
            one_shot=one_shot or false,
        }
		add(a.list, an)
	end
	function a:draw(x,y,flipx,flipy)
		local anim=a.current
		if not anim then
			rectfill(0,117, 128,128, 8)
			print("err: obj without animation!!!", 2, 119, 10)
			return
		end
		spr(a:_get_fr(a.current.one_shot, a.current.callback),x,y,anim.w,anim.h,flipx,flipy)
    end
	return a
end
function entity(anim_obj)
    local e={
        x=0,
        y=0,
        anim_obj=anim_obj,
        debugbounds=false,
        flipx=false,
        flipy=false,
        bounds=nil,
    }
    local flkr={
        timer=0,
        duration=0,     
        slowness=3,
        isflikrng=false 
    }
    e.flkr=flkr
    function flkr:flicker()
        if flkr.timer > flkr.duration then
            flkr.timer=0
            flkr.isflikrng=false
        else
            flkr.timer+=1
        end
        e.flkr=flkr
    end
    function e:setx(x)
        e.x=x
        if(e.bounds ~= nil) e.bounds:setx(x)
    end
    function e:sety(y)
        e.y=y
        if(e.bounds ~= nil) e.bounds:sety(y)
    end
    function e:setpos(x,y)
        e:setx(x)
        e:sety(y)
    end
    function e:set_anim(idx)
		e.anim_obj:set_anim(idx)
    end
    function e:set_bounds(bounds)
        e.bounds = bounds
        e:setpos(e.x, e.y)
    end
    function e:flicker(duration)
        if not flkr.isflikrng then
            flkr.duration=duration
            flkr.isflikrng=true
            flkr:flicker()
        end
        return flkr.isflikrng
    end
    function e:draw()
        if flkr.timer % flkr.slowness == 0 then
            e.anim_obj:draw(e.x,e.y,e.flipx,e.flipy)
        end
        if(flkr.isflikrng) flkr:flicker()
		if(e.debugbounds) e.bounds:printbounds()
    end
    return e
end

function timer(updatables, step, ticks, max_runs, func)
    local t={
        tick=0,
        step=step,
        trigger_tick=ticks,
        func=func,
        count=0,
        max=max_runs,
        timers=updatables,
    }
    function t:update()
        t.tick+=self.step
        if t.tick >= self.trigger_tick then
            t.func()
            t.count+=1
            if t.max>0 and t.count>=t.max and t.timers ~= nil then
                del(t.timers,self) 
            else
                t.tick=0
            end
        end
    end
    function t:kill()
        del(t.timers, t)
    end
    add(updatables,t) 
    return t
end

function tutils(args)
	local s={
		private={
			tick=0,
			blink_speed=1
		},
		height=10, 
		text=args.text or "",
		_x=args.x or 2,
		_y=args.y or 2,
		_fg=args.fg or 7,
		_bg=args.bg or 2,
		_sh=args.sh or 3, 	
		_bordered=args.bordered or false,
		_shadowed=args.shadowed or false,
		_centerx=args.centerx or false,
		_centery=args.centery or false,
		_blink=args.blink or false,
		_blink_on=args.on_time or 5,
		_blink_off=args.off_time or 5
	}
	function s:draw()
		if(s._centerx)s._x =  64-flr((#s.text*4)/2)
		if(s._centery)s._y = 64-(4/2)
		if s._blink then
			s.private.tick+=1
			local offtime=s._blink_on+s._blink_off 
			if(s.private.tick>offtime)s.private.tick=0
			local blink_enabled_on = false
			if(s.private.tick<s._blink_on)blink_enabled_on = true
			if(not blink_enabled_on) return
		end
		local yoffset=1
		if s._bordered then
			yoffset=2
		end
		if s._bordered then
			local x,y=max(s._x,1),max(s._y,1)
			if(s._shadowed)then
				for i=-1, 1 do	
					print(s.text, x+i, s._y+2, s._sh)
				end
			end
			for i=-1, 1 do
				for j=-1, 1 do
					print(s.text, x+i, y+j, s._bg)
				end
			end
		elseif s._shadowed then
			print(s.text, s._x, s._y+1, s._sh)
		end
		print(s.text, s._x, s._y, s._fg)
    end
	return s
end

function collides(ent1, ent2)
    local e1b, e2b = ent1.bounds, ent2.bounds
    if  ((e1b.xoff1 <= e2b.xoff2 and e1b.xoff2 >= e2b.xoff1)
    and (e1b.yoff1 <= e2b.yoff2 and e1b.yoff2 >= e2b.yoff1)) then 
        return 1
    end
    return nil
end
function point_collides(x,y, ent)
    local eb=ent.bounds
    if  ((eb.xoff1 <= x and eb.xoff2 >= x)
    and (eb.yoff1 <= y and eb.yoff2 >= y)) then
        return 1
    end
    return nil
end
function point_collides(x,y, ent)
    local eb=ent.bounds
    if  ((eb.xoff1 <= x and eb.xoff2 >= x)
    and (eb.yoff1 <= y and eb.yoff2 >= y)) then
        return true
    end
    return false
end
--  --<*sff/explosions.lua
--  --<*sff/buttons.lua

local tick_dance,step_dance=0,0
function dance_bkg(delay,color)
    local sp,pat=delay,0b1110010110110101
    tick_dance+=1
    if tick_dance>=sp then
        tick_dance=0
        step_dance+=1
        if(step_dance>=16) step_dance = 0
    end
    fillp(bxor(shl(pat,step_dance), shr(pat,16-step_dance)))
    rectfill(0,0,64,64,color)
    rectfill(64,64,128,128,color)
    fillp(bxor(shr(pat,step_dance), shl(pat,16-step_dance)))
    rectfill(64,0,128,64,color)
    rectfill(0,64,64,128,color)
    fillp() 
end
function menu_state()
    local state,texts,ypos,frbkg,frfg={},{},111,1,6
	add(texts, tutils({text="confused",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
	add(texts, tutils({text="rombosaur studios",centerx=true,y=99,fg=9,sh=2,shadowed=true}))
	add(texts, tutils({text="press ❎ to start", blink=true, on_time=15, centerx=true,y=80,fg=0,bg=1,shadowed=true, sh=7}))
	add(texts, tutils({text="v0.1", x=106, y=97}))
	add(texts, tutils({text="🅾️             ❎  ", centerx=true, y=ypos, shadowed=true, bordered=true, fg=8, bg=0, sh=2}))
	add(texts, tutils({text="  buttons  ", centerx=true, y=ypos, shadowed=true, fg=7, sh=0}))
    add(texts, tutils({text="  c         v  ", centerx=true, bordered=true, y=ypos+3, fg=8, bg=0}))
    ypos+=10
	local x1=28
	local y1=128-19
	local x2=128-x1-2
	local y2=128
	state.update=function()
        if(btnp(5)) curstate=game_state() sfx(5)
	end
	cls()
	state.draw=function()
		dance_bkg(10,frbkg)
		rectfill(3,2, 128-4, 104, 7)
		rectfill(2,3, 128-3, 103, 7)
		rectfill(4,3, 128-5, 103, 0)
		rectfill(3,4, 128-4, 102, 0)
		rectfill(5,4, 128-6, 102, frfg)
		rectfill(4,5, 128-5, 101, frfg)
		rectfill(25,97,  101, 111, frbkg)
		rectfill(24,98,  102, 111, frbkg)
		pset(23,104,frbkg)
		pset(103,104,frbkg)
        rectfill(x1,y1-1,  x2,y2+1, 0)
		rectfill(x1-1,y1,  x2+1,y2, 0)
		rectfill(x1,y1,  x2,y2, 6)
        for t in all(texts) do
            t:draw()
        end
	end
	return state
end
function game_state()
    local s={}
    local cam={ x=0, y=0 }
    local updateables={}
    local drawables={}
    local updrawables={}
    local g={}
    s.g=g
    g.stage=1
    function h(x,y)
        local anim_obj=anim()
        anim_obj:add(1,2,0.1,1,1)  
        anim_obj:add(16,2,0.2,1,1) 
        anim_obj:add(32,2,0.2,1,1) 
        anim_obj:add(48,2,0.2,1,1) 
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        e.spd = 1
        function e:update()
            if(g.stage == 3)e:set_anim(2)
            if(g.stage == 4)e:set_anim(3)
            if(g.stage == 5)e:set_anim(4)
            local ori = { x=e.x, y=e.y }
            if btn(0) then     
                e:setx(e.x-e.spd)
                e.flipx=true
            elseif btn(1) then 
                e:setx(e.x+e.spd)
                e.flipx=false
            end
            if btn(2) then          
                e:sety(e.y-e.spd)
            elseif btn(3) then  
                e:sety(e.y+e.spd)
            end
            if btnp(4) then 
            end
            if btnp(5) then 
            end
            if fget(mget(e.x/8, e.y/8)) > 0 then
                e:setx(ori.x)
                e:sety(ori.y)
            end
            cam.x = e.x - 64
            cam.y = e.y - 64
        end
        return e
    end
    function hut(x,y)
        local anim_obj=anim()
        anim_obj:add(64,1,0.1,4,2)  
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(32,16)
        e:set_bounds(bounds_obj)
        e.hide=true
        function e:update()
            if not e.hide and collides(g.hero,e) then
                g.words.s=0x0
                g.words.w={""}
                sfx(2)
                curstate=chaman_state(g.stage,s)
                g.stage+=1
            end
        end
        e.dd=e.draw
        function e:draw()
            if not e.hide then
                self:dd()
            end
        end
        return e
    end
    function human(x,y,v,bit)
        local anim_obj=anim()
        local sp = 36
        if(v==2) sp=sp+2
        if(v==3) sp=sp+4
        anim_obj:add(sp,2,0.1,1,1)  
        anim_obj:add(51,1,0.1,1,1)  
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        e.fuse = true
        e.dfuse=true
        function e:update()
            if collides(e,g.hero) and e.fuse then
                sfx(0)
                e.fuse = false
                g.words:state(bit)
            end
            if not e.fuse then
                e:set_anim(2)
                if e.dfuse then
                    e.dfuse=false
                    add(updrawables, soul(e.x,e.y-10))
                end
            end
        end
        return e
    end
    function soul(x,y)
        local anim_obj=anim()
        anim_obj:add(54,2,0.1,1,2)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
        e.fuse = true
        function e:update()
            if e.fuse and e.y > cam.y then
                e.fuse = false
            else
                e:sety(e.y-2)
            end
        end
        return e
    end
    function words()
        local e={}
        e.s=0x0
        e.w={"_","_","_"}
        e.f=true
        function e:state(bit)
            e.s=bit
        end
        function e:update()
            if(band(e.s,0x1) >0)e.w={"find",e.w[2],e.w[3]}
            if(band(e.s,0x2) >0)e.w={e.w[1],"the",e.w[3]}
            if(band(e.s,0x4) >0)e.w={e.w[1],e.w[2],"hut"}
            if not (e.w[1]=="_" or e.w[2]=="_" or e.w[3]=="_") and e.f then
                e.f=false
                e.tt._blink=true
                e.tt._on_time=100
                e.tt._off_time=1
                g.hut.hide=false
            end
        end
        e.tt = tutils({text="",centerx=true,bordered=true,x=2,y=2,fg=7,bg=2})
        function e:draw()
            local t =""
            for w in all(e.w) do
                t=t..w.." "
            end
            local c={ xx=cam.x, yy=cam.y }
            camera(0,0)
            rectfill(0,0,128,7,0)
            e.tt.text=t
            e.tt.draw()
            camera(c.xx, c.yy)
        end
        return e
    end
    function bone(x,y)
        local anim_obj=anim()
        anim_obj:add(5,1,0.1,1,1)  
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        e.fuse=true
        function e:update()
            if g.stage==2 and e.fuse and collides(e, g.hero) then
                sfx(1)
                e.fuse = false
                g.hut.hide=false
            end
        end
        e.d=e.draw
        function e:draw()
            if(e.fuse)e:d()
        end
        return e
    end
    function pig(x,y)
        local anim_obj=anim()
        anim_obj:add(34,2,0.1,1,1)  
        anim_obj:add(51,1,0.1,1,1)  
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.spd=0.2
        e.flipt=250
        e.dir=1
        e.t=1
        e.fuse = true
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        function e:update()
            if e.fuse then
                e.t+=1
                if e.t >= e.flipt then
                    e.dir*=-1 
                    e.t=1
                    e.flipx=not e.flipx
                end
                e:setx(e.x+(e.spd*e.dir))
                e:sety(e.y+((e.spd/15)*e.dir))
            end
            if g.stage>=3 and collides(e,g.hero) and e.fuse then 
                sfx(0)
                e:set_anim(2)
                e.fuse=false
                add(updrawables, soul(e.x,e.y-10))
                if(g.stage==3) g.hut.hide=false
            end
        end
        return e
    end
    function mhouse(x,y)
        local anim_obj=anim()
        anim_obj:add(10,1,0.1,1,2)  
        anim_obj:add(11,1,0.1,2,2)  
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.fuse = true
        local bounds_obj=bbox(8,15)
        e:set_bounds(bounds_obj)
        function e:update()
            if g.stage>=4 and collides(e,g.hero) and e.fuse then 
                sfx(0)
                e:set_anim(2)
                e.fuse=false
                add(updrawables, soul(e.x,e.y-10))
                if(g.stage==4) g.hut.hide=false
            end
        end
        return e
    end
    g.hero = h(30,30)
    add(updrawables, g.hero)
    g.hut = hut(190,120)
    add(updrawables, g.hut)
    g.humans={}
    add(g.humans,human(34*8,2*8,1,0x1))
    add(g.humans,human(9*8,16*9,2,0x2))
    add(g.humans,human(11*8,4*8,3,0x4))
    foreach(g.humans, function(v) add(updrawables, v)end)
    g.pigs={}
    add(g.pigs,pig(24*8,2*8))
    add(g.pigs,pig(2*8,17*8))
    add(g.pigs,pig(36*8,7*8))
    foreach(g.pigs, function(v) add(updrawables, v)end)
    add(updrawables, mhouse(39*8, 12*8))
    g.words = words()
    add(updrawables, g.words)
    g.mw=48
    g.mh=21
    local trees={}
    for i=1,g.mw do
        for j=1,g.mh do
            local xx = mget(i,j)
            if(xx == 68 or xx == 69) add(trees, {x=i*8,y=j*8})
        end
    end
    local tx = trees[flr(rnd(#trees))+1]
    printh(tx.x)
    printh(tx.y)
    local b = bone(tx.x,tx.y)
    add(updrawables, b)
    s.update=function()
        for u in all(updateables) do
            u:update()
        end
        for u in all(updrawables) do
            u:update()
        end
        camera(cam.x, cam.y)
    end
    s.draw=function()
        cls()
        map(0, 0, 0, 0, g.mw, g.mh)
        for d in all(drawables) do
            d:draw()
        end
        for d in all(updrawables) do
            d:draw()
        end
    end
    return s
end

function gameover_state()
    local s,texts,timeout,frbkg,frfg,ty,restart_msg,msg={},{},2,8,6,15,"press ❎ to restart"
        ,tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    music(-1)
    sfx(-1)
    add(texts, tutils({text="game over ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         " ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="don't let the chaman get ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="away with it!            ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, msg)
    s.update=function()
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=gfight_state() 
    end
    cls()
    s.draw=function()
        dance_bkg(10,frbkg)
        local frame_x0, frame_y0 = 10,10
        local frame_x1,frame_y1=128-frame_x0,128-frame_y0
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
        if timeout > 0 then
            local t = flr(timeout) + 1
            msg.text = "wait for it... ("..t..")"
        else
            msg.text = restart_msg
        end
        for t in all(texts) do
            t:draw()
        end
    end
    return s
end
function win_state()
    local s,texts,timeout,frbkg,frfg,ty,restart_msg,msg={},{},2,11,6,15,"press ❎ to restart"
        ,tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    music(-1)
    sfx(-1)
    add(texts, tutils({text="congfarkltulations!",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="thanks for so much," ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="sorry for so little.",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="ld45 entry",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, msg)
    s.update=function()
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=menu_state() 
    end
    cls()
    s.draw=function()
        dance_bkg(10,frbkg)
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
        if timeout > 0 then
            local t = flr(timeout) + 1
            msg.text = "wait for it... ("..t..")"
        else
            msg.text = restart_msg
        end
        for t in all(texts) do
            t:draw()
        end
    end
    return s
end
function chaman_state(stage, cb)
    local state,texts,ypos,frfg={},{},111,5
	local ypos=23
	add(texts, tutils({text="chaman's layer",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
	add(texts, tutils({text="press ❎ to restart", blink=true, on_time=15, centerx=true,y=110,fg=7,bg=1,bordered=false,shadowed=true,sh=0}))
	function to(t,ypos)return {text=t,centerx=true,shadowed=true,x=5,y=ypos,fg=7,sh=0} end
	if stage==1 then
		add(texts, tutils(to("hi billy. i know you want to",ypos))) ypos+=10
		add(texts, tutils(to("be human again. it's been so",ypos))) ypos+=10
		add(texts, tutils(to("long you probably don't",ypos))) ypos+=10
		add(texts, tutils(to("remember how that feels like.",ypos))) ypos+=20
		add(texts, tutils(to("search for bones in the trees",ypos))) ypos+=10
		add(texts, tutils(to("bring the bones to me and i'll",ypos))) ypos+=10
		add(texts, tutils(to("make you human again.",ypos))) ypos+=10
	elseif stage==2 then
		add(texts, tutils(to("good billy. you can be a ",ypos))) ypos+=10
		add(texts, tutils(to("skeleton now. bring me some",ypos))) ypos+=10
		add(texts, tutils(to("animal flesh and i'll give you",ypos))) ypos+=10
		add(texts, tutils(to("muscles.",ypos))) ypos+=10
	elseif stage==3 then
		add(texts, tutils(to("excellent! you're so close",ypos))) ypos+=10
		add(texts, tutils(to("billy. there's a final thing i",ypos))) ypos+=10
		add(texts, tutils(to("need... find your soul, billy.",ypos))) ypos+=10
		add(texts, tutils(to("and you'll be human again.",ypos))) ypos+=10
	elseif stage==4 then
		add(texts, tutils(to("yes, finally! you're a human.",ypos))) ypos+=10
		add(texts, tutils(to("you are the missing ingredient",ypos))) ypos+=10
		add(texts, tutils(to("for setting myself free from ",ypos))) ypos+=10
		add(texts, tutils(to("this haunted hut.",ypos))) ypos+=10
	end
	local enf=30
	state.update=function()
		cb.g.hut.hide=true
		if stage >= 4 then
			enf=80
		end
		if btnp(5) then
			sfx(3)
			if stage >= 4 then
				curstate=gfight_state()
			else 
				curstate=cb 
			end
		end
	end
	cls()
	local t=0
	local s = 64
	state.draw=function()
		t+=0.01
		camera(0,0)
		rectfill(3-2,2, 128-4, 128-4, 7)
		rectfill(2-2,3, 128-3, 128-3, 7)
		rectfill(4-2,3, 128-5, 128-5, 0)
		rectfill(3-2,4, 128-4, 128-4, 0)
		rectfill(5-2,4, 128-6, 128-6, frfg)
		rectfill(4-2,5, 128-5, 128-5, frfg)
		local w = sin(t)*enf+50
        local h= sin(t)*enf+50
		sspr(16,8, 8,8, 64-(w/2),64-(h/2), w, h)
        for t in all(texts) do
            t:draw()
        end
	end
	return state
end
function gfight_state()
    music(2)
    local s={}
    local updateables={}
    local drawables={}
    local bullets={}
    local collideborders=true
    camera(0,0)
    local cam={x=0, y=0}
    function bullet(x,y, dir, spd, bullets, dmg)
        local e=entity({})
        e:setpos(x,y)
        e.dir=dir
        e.spd=spd
        e.dmg=dmg
        local bounds_obj=bbox(8,8,0,0,4,6)
        e:set_bounds(bounds_obj)
        function e:update()
            self:setx(self.x+(self.spd*self.dir))
            if(self.x > cam.x+127)  self:kill()
            if(self.x < cam.x)      self:kill()
        end
        function e:kill()
            del(bullets,self)
        end
        function e:draw()
            spr(72, self.x, self.y, 1,1)
        end
        return e
    end
    function hero(x,y, bullets, platforming_state)
        local anim_obj=anim()
        local e=entity(anim_obj)
        anim_obj:add(96,4,0.3,1,2) 
        anim_obj:add(100,1,0.01,1,2) 
        anim_obj:add(101,1,0.01,1,2) 
        anim_obj:add(102,1,0.5,2,2,true, function() e.shooting=false end) 
        e:setpos(x,y)
        e:set_anim(2) 
        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
        e.speed=2
        e.floory=y
        e.jumppw=7
        e.grav=0.01
        e.baseaccel=1
        e.accel=e.baseaccel
        e.grounded=true
        e.shooting=false
        e.wasshooting=false
        e.compensate=false
        e.compensatepx=-8
        e.bulletspd=4
        e.health=20
        e.dmg=1
        e.finalboss=false
        e.potions=0
        e.notifyjumpobj={}
        e.codes={}
        e.codes.dir='none'
        e.codes.exit=false
        e.codes.dircode='none'
        e.btimer=0
        e.prevsh=-6300
        e.memslots={}
        add(e.memslots,"empty")
        add(e.memslots,"empty")
        add(e.memslots,"empty")
        function e:hurt(dmg)
            if(e.flkr.isflikrng) return
            self:flicker(30)
            self.health-=dmg
            sfx(5)
            if self.potions > 0 and self.health < 15 then
                self.potions-=1
                self.health+=5
            end
            if self.health <= 0 then
                music(-1)
                sfx(17)
                curstate=gameover_state()
                pendingmusic=true
                self:reset()
            end
        end
        function e:set_notifyjumpobj(obj)
            self.notifyjumpobj=obj
        end
        function e:controlls()
            self.btimer+=1
            if not self.shooting then
                if self.wasshooting then
                    self.wasshooting=false
                    if self.compensate then
                        self.compensate=false
                        self:setx(self.x-self.compensatepx)
                    end
                end
                if btn(0) then     
                    self:setx(self.x-self.speed)
                    self.flipx=true
                    self:set_anim(1) 
                elseif btn(1) then 
                    self:setx(self.x+self.speed)
                    self.flipx=false
                    self:set_anim(1) 
                else
                    self:set_anim(2) 
                end
                if btnp(4) and self.grounded then 
                    sfx(5)
                    self.grav = -self.jumppw
                    self:sety(self.y + self.grav)
                    self.grounded=false
                    self:set_anim(3) 
                elseif not self.grounded then
                    self:set_anim(3) 
                end
                if btnp(5) then 
                    if(self.btimer-self.prevsh < 10) return 
                    self.prevsh=self.btimer
                    sfx(4)
                    self.shooting=true
                    self.wasshooting=true
                    self:set_anim(4) 
                    local dir=1     
                    if self.flipx then
                        dir=-1      
                        self.compensate=true
                        self:setx(self.x+self.compensatepx)
                        self.bounds.xoff1+=8
                        self.bounds.xoff2+=8
                    end
                    local b=bullet(self.x+4, self.y+4, dir, self.bulletspd, bullets, self.dmg)
                    add(bullets, b)
                end
            end
        end
        function e:update()
            self:controlls()
            if self.y < self.floory then
                self:sety(self.y + self.grav)
                self.grav += self.baseaccel * self.accel
                self.accel+=0.1
            else
                self.grav = 0.01
                self.accel = self.baseaccel
                self.grounded=true
            end
            if self.y > self.floory then
                self:sety(self.floory)
                self.grounded=true
            end
        end
        function e:reset()
            self.respawned=true
            self.speed=2
            self.floory=y
            self.jumppw=7
            self.grav=0.01
            self.baseaccel=1
            self.accel=e.baseaccel
            self.grounded=true
            self.shooting=false
            self.wasshooting=false
            self.compensate=false
            self.compensatepx=-8
            self.bulletspd=4
            self.health=20
            self.potions=0
            self.codes.dir='none'
            self.codes.exit=false
            self.codes.dircode='none'
            if self.finalboss then
                self.finalboss=false
                deferpos=750 
            end
        end
        return e
    end
    local h=hero(120,70, bullets, s)
    h.x=10
    add(updateables,h)
    add(drawables,h)
    function miniboss(x,y,ebullets)
        local anim_obj=anim()
        local bounds_obj=bbox(16,16)
        anim_obj:add(151,2,0.2,3,4)
        bounds_obj=bbox(24,24)
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.health=30
        e:set_bounds(bounds_obj)
        function e:hurt(dmg)
            self:flicker(10)
            e.health-=dmg
            sfx(6)
            if self.health <= 0 then
                curstate=win_state()
            end
        end
        function bul(x,y, bullets)
            local anim_obj=anim()
            anim_obj:add(44,2,0.2,1,1)
            local e=entity(anim_obj)
            e:setpos(x,y)
            e:set_anim(1)
            local bounds_obj=bbox(8,8,0,0,4,4)
            e:set_bounds(bounds_obj)
            e.spd=1.8
            e.tick=0
            e.middle=y
            e.dmg=3
            function e:update()
                self.tick+=0.05
                self:setx(self.x-self.spd)
                self:sety( sin(self.tick) *10 + self.middle+flr(rnd(3)))
            end
            function e:kill()
                del(bullets,self)
            end
            return e
        end
        e.tick=0
        e.bulltick=0
        function e:update()
            local spdt=0.01
            self.tick+=spdt
            self:sety( sin(self.tick) *20 + 50)
            self:setx( self.x + sin(self.tick) )
            if flr(sin(self.tick)) % 2 == 0 then
                if self.bulltick < 100  then
                    self.bulltick+=0.5
                    if(self.bulltick % 10 == 0) add(ebullets, bul(self.x, self.y, ebullets)) sfx(4)
                end
            else
                self.bulltick=0
            end
        end
        return e
    end
    function updateblts(bullets, enemies, priest)
        for b in all(bullets) do
            b:update()
            for e in all(enemies) do
                if not priest or (not e.dying and e.born) then
                    if collides(b, e) then
                        b:kill()
                        e:hurt(b.dmg)
                        break
                    end
                end
            end
        end
    end
    local ebullets={}
    local xx=105
    local ghost=miniboss(xx, 60, ebullets)
    add(updateables, ghost)
    add(drawables, ghost)
    s.update=function()
        for u in all(updateables) do
            u:update()
        end
        updateblts(bullets, {ghost}, false)
        updateblts(ebullets, {h}, false)
        if(collides(h,ghost)) h:hurt(6)
        if(not collideborders) return
        if(h.x < 1) h:setx(1)
        if(h.x >118) h:setx(118)
    end
    local ins = tutils({text="🅾️ - jump   ❎ - shoot",centerx=true,y=40,fg=6})
    s.draw=function()
        camera(0,0)
        cls()
        fillp(0b0000001010000000)
        rectfill(0,0,127,127, 2) 
        fillp(0)
        rectfill(0,70,127,127, 0) 
        rectfill(0,38, 128, 38+8, 0)
        ins:draw()
        for d in all(drawables) do
            d:draw()
        end
        for d in all(bullets) do
            d:draw()
        end
        for d in all(ebullets) do
            d:draw()
        end
        local xx=35
        local yy=2
        rectfill(0,0, 128,8, 0)
        print("boss", 2,2, 9)
        rectfill(xx,yy,  xx+(ghost.health*2),yy+3, 9)
        rectfill(xx,yy+1,  xx+(ghost.health*2),yy+2, 8)
        local xx=35
        local yy=120
        rectfill(0,yy-3, 128,128, 0)
        print("hero", 2,yy-1, 9)
        rectfill(xx,yy,  xx+(h.health*2),yy+3, 9)
        rectfill(xx,yy+1,  xx+(h.health*2),yy+2, 8)
    end
    return s
end
--------------------------- end imports

-- to enable mouse support uncomment all of the following commented lines:
-- poke(0x5f2d, 1) -- enables mouse support
function _init()
    music(1)
    curstate=menu_state()
    --curstate=game_state()
    --curstate=gfight_state()
    --curstate=chaman_state(1)
end

function _update()
    -- mouse utility global variables
    -- mousex=stat(32)
    -- mousey=stat(33)
    -- lclick=stat(34)==1
    -- rclick=stat(34)==2
    -- mclick=stat(34)==4
	curstate.update()
end

function _draw()
    curstate.draw()
    -- pset(mousex,mousey, 12) -- draw your pointer here
end
__gfx__
00000000007777700077777000055000000000000077077000000004000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777700070707005555550000550000077777000000400000000000000000000000000000000000000000000000000000000000000000000000000
000000000770707007777770055555500055550000007700000000040000000000000000000000000cccccc00000000000000000000000000000000000000000
000000000777777007777770000550000511155000077000000004000000000000000000000000000caaaac00000000000000000000000000000000000000000
000000000777777007777770000550000555555000770000000000040000000000000000000000000a8aa8a00000000000000000000000000000000000000000
00000000077777700777777000055000051511500770000000000400404040400000040440400000087887800000000000000000000000000000000000000000
000000000777777007777770000550000555555077777000000000040000000000000000000000000a8aa8a0018c8c0000000000000000000000000000000000
000000000707707000770700005555000511515077077000000004000404040400000404404000000aaaaaa008cca90777000000000000000000000000000000
00666600006666000111122000888800003333000033330040000000040404040000040440400000eeeeeeee0cc8788070000000000000000000000000000000
00606000006606001115512280888808003737000033730000400000000000000000000000000000eeeeeeee0ca8890a70000000000000000000000000000000
00666600066666001155552288a88a88003333000033330040000000404040400000040440400000eeeeeeee0c89a0a990000000000000000000000000000000
00660600000666000115512088aaaa88003333000033330000400000000000000000000000000000aeeeeeea8c8aa9ae98000000000000000000000000000000
0600600000066000001111008899998803dddd00000dd000400000000000000000000000000000000999999089eaa9ee98000000000000000000000000000000
00066000000666000011210088888888000ddd30003ddd00004000000000000000000000000000000990099088e9eeee98800000000000000000000000000000
000606000060060001112210008998000001110000011030400000000000000000000000000000000aa00aa08888888888800000000000000000000000000000
00600600000000001111222100888800001001000010100000400000000000000000000000000000099009900888800000000000000000000000000000000000
0088880000888800000000000e0eeee00ffff0000ffff00004444000044440000ffff0000ffff0000000000000000000e88e0000088000000000000000000000
0080800000880800e000eee0e00e7e700ffdf0000fdfd000044d400004d4d0000ffdf0000fdfd00000000000000000008aa800008aa800000000000000000000
00888800088888000e00e7e00e0eeee00ffff0000ffff00004444000044440000ffff0000ffff00000000000000000008aa800008aa800000000000000000000
0088080000088800e000eeee0eeeeee00ffff0000ffff00004444000044440000ffff0000ffff0000000000000000000e88e0000088000000000000000000000
08008000000080000eeeeeee0eeeee00001100000011000000880000008800000022000000220000000000000000000000000000000000000000000000000000
00088000000888000eeeee000eeeee00001100000011000000880000008800000022000000220000000000000000000000000000000000000000000000000000
00080800008800800eeeee00e00e000000f1000000f10000004800000048000000f2000000f20000000000000000000000000000000000000000000000000000
00800800000000000e00e00000000000004400000044000000dd000000dd00000033000000330000000000000000000000000000000000000000000000000000
00ffff0000ffff000000000000000000000000000000000000000000000000000000000044444444444444440000000000000000000000000000000000000000
00fcfc0000ffcf00077777700000000000000000000000000000000000000000000000004ffffffffffffff40000000000000000000000000000000000000000
00ffff0000ffff00777777770000000000000000000000000000000000000000000000004ffffffffffffff40000000000000000000000000000000000000000
00ffff0000ffff00771717170077800000000000000000000000000000000000000000004ffffffffffffff40000000000000000000000000000000000000000
0f55550000055000777777770087090700000000000000000007770000777000000000004fff18c8cffffff40000000000000000000000000000000000000000
000555f000f55500077777000ff9908700000000000000000077777777777700000000004fff8cca9f777ff40000000000000000000000000000000000000000
00011100000110f00007700008f99ff000555000000000000700700770070070000000004fffcc8788f7fff40000000000000000000000000000000000000000
0010010000101000000700008888f8f800000500040000007000700000070007000000004fffca889fa7fff40000000000000000000000000000000000000000
0000000000000000000000000000000000000550004400007000700770070007067000004fffc89afa99fff40000000000000000000000000000000000000000
0000000000000445555550000000000000000050000400007777777777777777566500004ff8c8aa9ae98ff40000000000000000000000000000000000000000
0000000000044444455555000000000000055550000405007700007007000077055000004ff89eaa9ee98ff40000000000000000000000000000000000000000
0000000000444444555555550000000000055555500455000700007007000070000000004ff88e9eeee988f40000000000000000000000000000000000000000
0000000044444555555555555000000000050005500550000707707007077070000000004ff88888888888f40000000000000000000000000000000000000000
0000000444445555556655555500000000550005505554000077770000777700000000004fff8888fffffff40000000000000000000000000000000000000000
0000000444445566666666555550000005500005555004400007700000077000000000004ffffffffffffff40000000000000000000000000000000000000000
00000044444555556666666555550000000000455550000400007000000700000000000044444444444444440000000000000000000000000000000000000000
00000044445555500006666555550000000004055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000444455555600000666555550000000040005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000444555555600000666555555000000000004555500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000444555555600000666555555000000000054455500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004445555555600000666555555500000005555455000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044445555555600000666555555550000055455445000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444445555556600000666555555550000544455545500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444445555566600000666555555555005540005544550000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400000000000044440000000000000444400044440000000000000000000000000000000000000000000000000000000000000000000000000000000000
044fff00004444000044ff00004444000044fff0044fff0000444400000000000000000000000000000000000000000000000000000000000000000000000000
044fff000044ff000004ff000044ff000044fff0044fff00044fff00000000000000000000000000000000000000000000000000000000000000000000000000
004fff000044ff00000110000044ff000004fff0004fff00044fff00000000000000000000000000000000000000000000000000000000000000000000000000
004ff0000011100000111100001110000004ff00004ff00f004fff00000000000000000000000000000000000000000000000000000000000000000000000000
001110000111f000000f11000111f000000111f0001110f0004ff000000000000000000000000000000000000000000000000000000000000000000000000000
0111110001ff1000000fff0001ff10000001ff100111110000111111fff000000000000000000000000000000000000000000000000000000000000000000000
00ff11f0001110000000550000111000000011100f05550000111110000000000000000000000000000000000000000000000000000000000000000000000000
000ff50000555000000555500055500000005550f005005000111110000000000000000000000000000000000000000000000000000000000000000000000000
00055500005550000005505000555000000055500050005000f55500000000000000000000000000000000000000000000000000000000000000000000000000
00050550005550000000505000555000000055500100005000050550000000000000000000000000000000000000000000000000000000000000000000000000
00050050000500000005005000050000000005000010001100050050000000000000000000000000000000000000000000000000000000000000000000000000
00500050000500000050005000050000000005000000000000500050000000000000000000000000000000000000000000000000000000000000000000000000
01000050000500000011001100050000000005000000000001000050000000000000000000000000000000000000000000000000000000000000000000000000
00100011000110000000000000011000000001100000000000100011000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000007000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000070000000000660000007770000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000006660000077000000006600000000777000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000066000000007000000006600000000077000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000660000000007000000066000000000007700000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000066688000000077000000066000088000007770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000008888888888800077000000068888888888800770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000088888888888888777000000888888888888888770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000887778888888888777000088887778888888888770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000008877777888888887777000888877777888888887770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000088728777788888877770000888777777788888877770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000088722777788887777770000888772877788887777770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000888877777888887777780008888872277888887777780000000000000000000000000
00000000000000000000000000000000000000000000000000000000000888887778888887777780008888887778888887777780000000000000000000000000
00000000000000000000000000000000000000000000000000000000000888888888888887777780008888888888888887777780000000000000000000000000
00000000000000000000000000000000000000000000000000000000000888888888888888777880008888888888888888777880000000000000000000000000
00000000000000000000000000000000000000000000000000000000000880888888888888888880008888888888888888888880000000000000000000000000
00000000000000000000000000000000000000000000000000000000000008887777888888888880008880088877228888888880000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007777277222888888880000888088777222888888880000000000000000000000000
00000000000000000000000000000000000000000000000000000000000077777272222888888880000008887227222888888880000000000000000000000000
00000000000000000000000000000000000000000000000000000000000777000222222888888880000000877722222888888880000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000022272888888880000000777722222888888880000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000227888888800000000770022272888888800000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000002727888888800000000770027227888888800000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000072778888888000000000070722777888888000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007077888888880000000000000777788888888000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000788888880000000000000007888888888880000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000888880000000000000000000888888888800000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000088000000000000000000000088888880000000000000000000000000000000
__gff__
0000000000000101010100000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0807070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000000000000000000000000044450044450000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000044450000000000000000000000000000000000000000000000000054554445554445160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000054550000000000000000000000000000000000000000000000000000005455444555160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000000000000000000000004445000000545500160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000000000000000000000005455000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000444500000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000545500000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000004445000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000044450000000000000000005455000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000054550000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000000000000000004445000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000444500000000000000000000000000000000000000000000000000000000005455000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000545500000000000000000000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000044450000000000000000000000000000000000000000000044450000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000054550000000000000000000000000000000000000000000054550000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1817171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000f0500f0500f550115501155013050160501605016050130500f0500a0500705005050000500105000050096000760006600046000260002600036000360003600036000360003600036000260001600
0001000023050000002a050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016000160001600017000000001b000000002100014000
0003000022050000002205000000220502e0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000f05018050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b1501b15016150111500a150071500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000160201b0201b0201d0201f020270202e02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000305005050031500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000200f050066000f0500560003000030000300005600030000460003000046000300004600030000f050036000f05003000036000300003000030000360003000036000a0000360003000036000300004600
001000200f050066000f0500560003050030000305005600030500460003050046000305004600030500f050036000f05003050036000305003000030500360003050036000a0500360003050036000305004600
01100000000000000000000000001c653000000000000000000000000000000000001c653000000000000000000000000000000000001c653000000000000000000000000000000000001c653000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000000000000000000000000000001c152000001c1522115200000000000000024152000002415200000231520000000000000000000000000000000f152000001f152000001f152000001c1521f15200000
0110000013156101561a1560e156300000000000000000000000000000000000000013156101560e1560e156000000000029053000002805326053000000000013156101560e1560e15600000000000000000000
__music__
01 07484b44
00 07094b44
00 08094b44
00 08094b44
00 08090c44
00 48090c44
02 07490c44

