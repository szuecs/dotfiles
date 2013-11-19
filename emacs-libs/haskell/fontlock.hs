-- Comments are coloured brightly and stand out clearly.

repeat :: a -> [a]
repeat xs = xs where xs = x:xs          -- Keywords are also bright.

head :: [a] -> a
head (x:_) = x
head [] = error "PreludeList.head: empty list" -- Strings are coloured softly.

data Maybe a = Nothing | Just a              -- Type constructors, data
             deriving (Eq, Ord, Read, Show)  -- constructors, class names
                                             -- and module names are coloured
                                             -- closer to ordinary code.

{-
map :: (a -> b) -> [a] -> [b]           -- Commenting out large sections of
map f []     = []                       -- code can be misleading.  Coloured
map f (x:xs) = f x : map f xs           -- comments reveal unused definitions.
-}
