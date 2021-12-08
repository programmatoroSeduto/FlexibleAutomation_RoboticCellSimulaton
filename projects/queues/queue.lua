--
--- QUEUE
--

--- Init the queue
function queue_init( )
    local queue = {  }
    
    -- basic infos
    queue.data = { }
    queue.size = 0
    
    --- METHOD : enqueue an item
    function queue.push( self, item )
        table.insert( self.data, item )
        self.size = self.size + 1
    end
    --
    
    --- METHOD : dequeue
    function queue.pop( self )
        if self.size == 0 then
            return nil
        end
        
        local temp = self.data[ 1 ]
        table.remove( self.data, 1 )
        self.size = self.size - 1
        
        return temp
    end
    --
    
    --- METHOD : print the queue
    function queue.print( self )
        print( "queue: (size: " .. self.size .. ")" )
        print( self.data )
    end
    --
    
    --- METHOD : inspect next value
    function queue.next( self )
        if self.size == 0 then
            return nil
        else
            return self.data[1]
        end
    end
    
    return queue
end
--



function sysCall_init()
    local Q = queue_init( )
    Q.push( Q, 1 )
    Q.print( Q )
    Q.push( Q, 3 )
    Q.print( Q )
    Q.push( Q, 5 )
    Q.print( Q )
    Q.push( Q, 4 )
    Q.print( Q )
    Q.push( Q, 7 )
    Q.print( Q )
    print( "pop: " .. Q.pop( Q ) )
    print( "next: " .. Q.next( Q ) )
    Q.print( Q )
    print( "pop: " .. Q.pop( Q ) )
    print( "next: " .. Q.next( Q ) )
    Q.print( Q )
    print( "pop: " .. Q.pop( Q ) )
    print( "next: " .. Q.next( Q ) )
    Q.print( Q )
    print( "pop: " .. Q.pop( Q ) )
    print( "next: " .. Q.next( Q ) )
    Q.print( Q )
    print( "pop: " .. Q.pop( Q ) )
    Q.print( Q )
end