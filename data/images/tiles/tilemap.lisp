;; Vlang the game tilemap
;;
;; Tile definition:
;; (tile id file-id xpos ypos type)
;;
;; Tile types:
;; - 0: background
;; - 1: solid

(tilemap
    (file 0 "tiles.png")

    (tile 64 0 4 0 1)
    (tile 65 0 0 0 1)
    (tile 66 0 1 0 1)
    (tile 68 0 2 0 1)
    (tile 69 0 3 0 1))