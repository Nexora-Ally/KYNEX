local Pathfinder = {}
Pathfinder.__index = Pathfinder

-- Konstanta arah (4 arah: atas, kanan, bawah, kiri)
local directions = {
    Vector2.new(0, 1),
    Vector2.new(1, 0),
    Vector2.new(0, -1),
    Vector2.new(-1, 0)
}

function Pathfinder.new(gridSize, cellSize, originPosition)
    local self = setmetatable({}, Pathfinder)
    self.GridSize = gridSize -- Ukuran grid (X, Y)
    self.CellSize = cellSize -- Ukuran setiap sel dalam stud
    self.Origin = originPosition -- Posisi bawah kiri grid (World CFrame)
    self.Obstacles = {} -- Tabel untuk menyimpan obstacle
    return self
end

-- Tambah obstacle berdasarkan koordinat grid
function Pathfinder:AddObstacle(gridX, gridY)
    self.Obstacles[gridX .. "," .. gridY] = true
end

-- Cek apakah sel aman untuk dilalui
function Pathfinder:IsCellWalkable(x, y)
    return not self.Obstacles[x .. "," .. y]
        and x >= 1 and x <= self.GridSize.X
        and y >= 1 and y <= self.GridSize.Y
end

-- Konversi posisi dunia ke koordinat grid
function Pathfinder:WorldToGrid(worldPos)
    local localPos = self.Origin:PointToObjectSpace(worldPos)
    local x = math.floor(localPos.X / self.CellSize) + 1
    local y = math.floor(localPos.Z / self.CellSize) + 1
    return Vector2.new(x, y)
end

-- Konversi koordinat grid ke posisi dunia
function Pathfinder:GridToWorld(gridPos)
    return self.Origin * CFrame.new(
        (gridPos.X - 0.5) * self.CellSize,
        0,
        (gridPos.Y - 0.5) * self.CellSize
    )
end

-- Algoritma A* Pathfinding
function Pathfinder:FindPath(startWorld, goalWorld)
    local startGrid = self:WorldToGrid(startWorld)
    local goalGrid = self:WorldToGrid(goalWorld)

    -- Heuristic function (Manhattan distance)
    local function heuristic(a, b)
        return math.abs(a.X - b.X) + math.abs(a.Y - b.Y)
    end

    local openSet = {}
    local closedSet = {}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}

    -- Inisialisasi start node
    gScore[tostring(startGrid)] = 0
    fScore[tostring(startGrid)] = heuristic(startGrid, goalGrid)
    table.insert(openSet, startGrid)

    while #openSet > 0 do
        -- Cari node dengan fScore terendah
        table.sort(openSet, function(a, b)
            return fScore[tostring(a)] < fScore[tostring(b)]
        end)
        local current = table.remove(openSet, 1)

        -- Jika mencapai goal
        if current.X == goalGrid.X and current.Y == goalGrid.Y then
            local path = {}
            while cameFrom[tostring(current)] do
                table.insert(path, 1, self:GridToWorld(current))
                current = cameFrom[tostring(current)]
            end
            table.insert(path, 1, startWorld)
            return path
        end

        closedSet[tostring(current)] = true

        -- Cek tetangga
        for _, dir in ipairs(directions) do
            local neighbor = Vector2.new(current.X + dir.X, current.Y + dir.Y)

            if self:IsCellWalkable(neighbor.X, neighbor.Y) then
                local neighborKey = tostring(neighbor)

                if not closedSet[neighborKey] then
                    local tentativeG = gScore[tostring(current)] + 1

                    if not gScore[neighborKey] or tentativeG < gScore[neighborKey] then
                        cameFrom[neighborKey] = current
                        gScore[neighborKey] = tentativeG
                        fScore[neighborKey] = tentativeG + heuristic(neighbor, goalGrid)

                        -- Tambah ke openSet jika belum ada
                        local exists = false
                        for _, node in ipairs(openSet) do
                            if node.X == neighbor.X and node.Y == neighbor.Y then
                                exists = true
                                break
                            end
                        end
                        if not exists then
                            table.insert(openSet, neighbor)
                        end
                    end
                end
            end
        end
    end

    return nil -- Tidak ditemukan jalan
end

return Pathfinder
