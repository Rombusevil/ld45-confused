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
        anim_obj:add(1,2,0.1,1,1)  -- ghost
        anim_obj:add(16,2,0.2,1,1) -- skeleton
        anim_obj:add(32,2,0.2,1,1) -- flesh
        anim_obj:add(48,2,0.2,1,1) -- human
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true
        e.spd = 1
        
        function e:update()
            if(g.stage == 3)e:set_anim(2)
            if(g.stage == 4)e:set_anim(3)
            if(g.stage == 5)e:set_anim(4)

            local ori = { x=e.x, y=e.y }
            if btn(0) then     --left
                e:setx(e.x-e.spd)
                e.flipx=true
            elseif btn(1) then --right
                e:setx(e.x+e.spd)
                e.flipx=false
            end

            if btn(2) then          --up
                e:sety(e.y-e.spd)
            elseif btn(3) then  --down
                e:sety(e.y+e.spd)
            end

            if btnp(4) then -- "O"

            end
 
            if btnp(5) then -- "X"

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
        anim_obj:add(64,1,0.1,4,2)  -- ghost
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(32,16)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true
        
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

    -- v= variation
    function human(x,y,v,bit)
        local anim_obj=anim()
        local sp = 36
        if(v==2) sp=sp+2
        if(v==3) sp=sp+4
        anim_obj:add(sp,2,0.1,1,1)  -- humna
        anim_obj:add(51,1,0.1,1,1)  -- dead
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true

        e.fuse = true
        e.dfuse=true
        
        function e:update()
            if collides(e,g.hero) and e.fuse then
                sfx(0)
                e.fuse = false
                g.words:state(bit)
            end
            if not e.fuse then
                --dead
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
        -- e.debugbounds=true

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
        anim_obj:add(5,1,0.1,1,1)  -- bone
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true
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
        anim_obj:add(34,2,0.1,1,1)  -- pig
        anim_obj:add(51,1,0.1,1,1)  -- dead
    
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
        -- e.debugbounds=true

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

            if g.stage>=3 and collides(e,g.hero) and e.fuse then --TODO: agregar validación de keypress
                --dead
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
        anim_obj:add(10,1,0.1,1,2)  -- pig
        anim_obj:add(11,1,0.1,2,2)  -- pig
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.fuse = true
    
        local bounds_obj=bbox(8,15)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true

        function e:update()
            if g.stage>=4 and collides(e,g.hero) and e.fuse then --TODO: agregar validación de keypress
                --dead
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

    -- add it last on purpose
    g.words = words()
    add(updrawables, g.words)

    -- map size
    g.mw=48
    g.mh=21
    -- get tree tiles branches position
    local trees={}
    for i=1,g.mw do
        for j=1,g.mh do
            local xx = mget(i,j)
            if(xx == 68 or xx == 69) add(trees, {x=i*8,y=j*8})
        end
    end
    -- randomize selection of bones tree
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


--function w(x,y,aid,h)
--    local anim_obj=anim()
--    anim_obj:add(6,1,0.1,1,1) -- left
--    anim_obj:add(7,1,0.1,1,1) -- top
--    anim_obj:add(22,1,0.1,1,1)-- right
--    anim_obj:add(23,1,0.1,1,1)-- down
--
--    local e=entity(anim_obj)
--    e:setpos(x,y)
--    e:set_anim(aid)
--
--    return e
--end

--build world boundaries
--local wt=300
--local ht=300
--local walls={}
--for c=0,wt/8 do
--    local zz = c
--    if c > 0 then
--        zz = c*8 
--    end
--    add(walls, w(0, zz, 1,hero))
--    add(walls, w(zz, 0, 2,hero))
--    add(walls, w(wt, zz, 3,hero))
--    add(walls, w(zz, ht, 4,hero))
--end
--foreach(walls, function(d) add(drawables, d)end)