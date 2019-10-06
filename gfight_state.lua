-- state
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
        -- e.debugbounds=true
    
        function e:update()
            self:setx(self.x+(self.spd*self.dir))

            -- kill the bullet if needed
            if(self.x > cam.x+127)  self:kill()
            if(self.x < cam.x)      self:kill()
        end

        function e:kill()
            del(bullets,self)
        end
        
        function e:draw()
            spr(72, self.x, self.y, 1,1)
            --if(self.debugbounds) self.bounds:printbounds()
        end
    
        return e
    end
    
    function hero(x,y, bullets, platforming_state)
        local anim_obj=anim()
        local e=entity(anim_obj)

        anim_obj:add(96,4,0.3,1,2) -- running
        anim_obj:add(100,1,0.01,1,2) -- idle
        anim_obj:add(101,1,0.01,1,2) -- jumping
        anim_obj:add(102,1,0.5,2,2,true, function() e.shooting=false end) -- shoot

        e:setpos(x,y)
        e:set_anim(2) --idle
    
        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
        --e.debugbounds=true

        e.speed=2--1.3
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

        -- this vars are loaded in the vertigo_state
        e.codes={}
        e.codes.dir='none'
        e.codes.exit=false
        e.codes.dircode='none'
        e.btimer=0
        e.prevsh=-6300
        e.memslots={}
        -- 3 mem slots only
        add(e.memslots,"empty")
        add(e.memslots,"empty")
        add(e.memslots,"empty")

        function e:hurt(dmg)
            if(e.flkr.isflikrng) return
            self:flicker(30)
            self.health-=dmg
            sfx(5)

            if self.potions > 0 and self.health < 15 then
                -- todo:sfx use potion
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

        -- every x jumps the obj spawns a new enemy
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

                if btn(0) then     --left
                    self:setx(self.x-self.speed)
                    self.flipx=true
                    self:set_anim(1) --running
                elseif btn(1) then --right
                    self:setx(self.x+self.speed)
                    self.flipx=false
                    self:set_anim(1) --running
                else
                    self:set_anim(2) --idle
                end
                
                -- the up button is taken care on the cabin entity
                
                if btnp(4) and self.grounded then -- "O"
                    -- jump
                    sfx(5)
                    self.grav = -self.jumppw
                    self:sety(self.y + self.grav)
                    self.grounded=false
                    self:set_anim(3) --jump
                elseif not self.grounded then
                    self:set_anim(3) --jump
                end
                
                if btnp(5) then -- "X"
                    -- shoot
                    if(self.btimer-self.prevsh < 10) return -- don't allow shooting like machine gun
                    self.prevsh=self.btimer

                    sfx(4)
                    self.shooting=true
                    self.wasshooting=true
                    self:set_anim(4) -- shoot
                    local dir=1     -- not flip
                    if self.flipx then
                        dir=-1      -- flip
                        -- flag compensate true
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
                --you're jumping
                self:sety(self.y + self.grav)
                self.grav += self.baseaccel * self.accel
                self.accel+=0.1
            else
                -- not jumping
                self.grav = 0.01
                self.accel = self.baseaccel
                self.grounded=true
            end

            if self.y > self.floory then
                -- compensate gravity
                self:sety(self.floory)
                self.grounded=true
            end
        end

        -- when you gameover and choose continue, everything's the same but your stats, that get resetted
        function e:reset()
            self.respawned=true
            self.speed=2--1.3
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

            -- make it so that if you loose you don't loose your memory
            -- self.memslots={}
            -- add(self.memslots,"empty")
            -- add(self.memslots,"empty")
            -- add(self.memslots,"empty")

            
            if self.finalboss then
                self.finalboss=false
                deferpos=750 -- lo mando al forest
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
        -- e.debugbounds=true

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
            -- e.debugbounds=true
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

            --movement
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

            -- check collisions between bullets and enemies
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

        -- collide with invisible walls
        if(not collideborders) return
        if(h.x < 1) h:setx(1)
        if(h.x >118) h:setx(118)
    end

    local ins = tutils({text="🅾️ - jump   ❎ - shoot",centerx=true,y=40,fg=6})

    s.draw=function()
        camera(0,0)
        cls()
        --rectfill(0,0,127,127, 1)

        -- wall
        fillp(0b0000001010000000)
        rectfill(0,0,127,127, 2) 

        -- floor
        --fillp(0b0000001010000000)
        --fillp(0b1111000100010001)
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

        
        -- ghost life bar
        local xx=35
        local yy=2
        rectfill(0,0, 128,8, 0)
        print("boss", 2,2, 9)
        rectfill(xx,yy,  xx+(ghost.health*2),yy+3, 9)
        rectfill(xx,yy+1,  xx+(ghost.health*2),yy+2, 8)

        -- hero life bar
        local xx=35
        local yy=120
        rectfill(0,yy-3, 128,128, 0)
        print("hero", 2,yy-1, 9)
        rectfill(xx,yy,  xx+(h.health*2),yy+3, 9)
        rectfill(xx,yy+1,  xx+(h.health*2),yy+2, 8)
    end

    return s
end