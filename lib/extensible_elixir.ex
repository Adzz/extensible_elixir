(
# Let's imagine we are a tile shop and we want to be able to calculate the cost of tiling an area
# the size of a given shape. The first thing we want to be able to do is to calculate the area of a
# shape. We can then times this by a cost_per_sq_m.

# Let's make some shapes.

square = %{side: 10}
circle = %{radius: 10}
triangle = %{base: 10, height: 30}

# As an aside, notice how these shapes are some kind of abstraction over shapes. We are saying that the only thing
# important about being a shape for our program right now, is that we can calculate an area,
# so we define the shape in terms of the things we need to be able to calculate the area.

# The simplest way we can get an area for each of these is to define an area function for each:

def square_area(square) do
  square.side * square.side
end

def circle_area(circle) do
  pi * circle.radius
end

def triangle_area(triangle) do
  triangle.base * triangle.height / 2
end


























# But this requires that we know what shape we have when we call it:

square_area(square)
# => Blows up!
square_area(circle)

# This is not extensible. We have to know too much about the type of thing we have, making it hard to abstract

# To combat this we could use the same name, but different arity:

def area(base, height) do
end

def area(radius) do
end

# Those will work like this:

area(triangle.base, triangle.height)
area(circle.radius)

# But very quickly we see that trying to implement area for a square will clash.

def area(side) do
end



























# The above is the same as the circle definition. And we still need to know what shape we have to be
# able to pull the right fields off.

# What about Pattern Matching!

def area(%{side: side}) do
  side * side
end

def area(%{radius: radius}) do
  pi * radius * radius
end

def area(%{base: base, height: height}) do
  triangle.base * triangle.height / 2
end


area(square)
area(circle)
area(triangle)

# This is mucchhh better. Now we can implement something like this:

def price_per_shape(shape, price_per_sqm) do
  area(shape) * price_per_sqm
end


# Notice how the calling site doesn't know about the different implantations of the area function
# That decoupling buys us the ability to add new shapes, and still have this function work.

# In order to add new shapes we just have to ensure we define a new case for the area function.
# There is however one limitation here. Imagine all of this code so far has been provided to us by
# a 3rd party lib. We want to use it, but we want to be able to add our own shapes. As is, we would
# have no way to be able to add a case for the area function - as we wouldn't have access to the source
# code.

# It is unreasonable
# to think the library author would be able to think of every possible shape that the users may require.
# so we need another way....
































# PROTOCOLS.

# Protocols dispatch based on type. That means our shapes now have to become types:

defmodule Square do
  defstruct [:side]
end

defmodule Circle do
  defstruct [:radius]
end


%Square{side: 10}
%Circle{radius: 10}













defprotocol Shape do
  def area(shape)
end

















defimpl Shape, for: Square do
  def area(shape) do
    shape.side * shape.side
  end
end
























defimpl Shape, for: Circle do
  def area(shape) do
    shape.radius * shape.radius * 3.14
  end
end


Shape.area(%Square{side: 10})
Shape.area(%Circle{side: 10})

# Elixir automatically knows to call the correct function based on the type of thing we pass in.
# And crucially we can add new implementations anywhere. Even if the protocol was originally defined
# in a third party library.





































# THE EXPRESSION PROBLEM

# This makes adding new shapes easy, but there is a problem. Our requirements change, and now we want
# to be able to calculate the cost for the perimeter of the shape. We want to be able to tile an outline
# And work out how much that costs.

# Now there are two ways that this can 'extend'.

# The first way, is we can add more shapes.
# The second way is the type of operation we want to perform on the shape. Eg perimeter or area

























# If we JUST wanted to be able to add new operations on the shapes we have, it would be easy.
defmodule Area do
  def calculate(shape) do
    case shape do
      %Square{side: side} -> side * side
      %Circle{radius: radius} -> radius * radius * 3.14
    end
  end
end

# Then if we wanted a perimeter function

defmodule Perimeter do
  def calculate(shape) do
    case shape do
      %Square{side: side} -> side * 4
      %Circle{radius: radius} -> radius * 2 * 3.14
    end
  end
end


























# But how do we add a triangle? Again, imagine this is defined in a third part lib and we don't have
# access to add another case.

# The challenge here is: how can we add both new shapes AND new operations on those shapes, without
# touching old code?

































# Let's first go back to our original implementation:

# Make some shapes
defmodule Square do
  defstruct [:side]
end

defmodule Circle do
  defstruct [:radius]
end










# define the protocol
defprotocol Shape do
  def area(shape)
end








# implement it for the Square
defimpl Shape, for: Square do
  def area(shape) do
    shape.side * shape.side
  end
end

# implement it for the Circle
defimpl Shape, for: Circle do
  def area(shape) do
    shape.radius * shape.radius * 3.14
  end
end



Shape.area(%Square{side: 10}) #=> 100
Shape.area(%Circle{radius: 10}) #=> 314.0


































# Now let's try adding a new protocol
defprotocol Perimeter do
  def calculate(shape)
end











defimpl Perimeter, for: Square do
  def calculate(square) do
    square.side * 4
  end
end

defimpl Perimeter, for: Circle do
  def calculate(circle)
    circle.radius * 2 * 3.14
  end
end




# Boom! If we want to add an operation, we add a new protocol. And if we need a new shape, we can
# just add implementations for any of the operations we want.

































# A STEP FURTHER

# That's good an all, but it would be nice to group all of the operations on shapes behind one module
# Given that they all operate on shapes, it would be nice to see something like:

Shape.calculate(%Area{}, %Square{side: 10})
Shape.calculate(%Perimeter{}, %Square{side: 10})
Shape.calculate(%Perimeter{}, %Circle{radius: 10})
Shape.calculate(%Area{}, %Circle{side: 10})



# Now we could do this:

defprotocol Shape do
  def area(shape)
  def perimeter(shape)
end

# But then we are back at square one - how do the library authors know all of the operations we might
# want on shapes? In short the operations are not extensible

# Instead we can get tricky... but beware it might be NSFW!





# let's define our protocol like this:
defprotocol Shape do
  def calculate(calculation, shape)
end











# protocols take the first argument and use that to decide where to go next. That means our calculation
# needs to be  a struct. We can get a bit tricky and define an empty struct like so:

defmodule Area do
  defstruct []
end

%Area{}












# This gives us the ability to provide an implementation for the Shape protocol for area:

defimpl Shape, for: Area do
  def calculate(%Area{}, shape) do
  end
end

# But what should go inside it?











# Well to maintain all the benefits we talked about before, we can call another protocol!
# Let's define that...

defprotocol AreaProtocol do
  def calculate(shape)
end






# This protocol takes a shape, so let's define an implementation for a square:
defimpl AreaProtocol, for: Square do
  def calculate(%Square{side: side}) do
    side * side
  end
end












# Now we can implement the Shape protocol by calling that:

defimpl Shape, for: Area do
  def calculate(%Area{}, shape) do
    AreaProtocol.calculate(shape)
  end
end


# Now let's step through what happens when we call it:

Shape.calculate(%Area{}, %Square{side: 2})


# This means we go to Shape.calculate/2, we know that the first arg is an area struct, so the implementation
# that runs is this:

  def calculate(%Area{}, shape) do
    AreaProtocol.calculate(shape)
  end

# Which calls AreaProtocol.calculate/1 passing in a square, meaning what gets called is the square
# implementation of the area function:

defimpl AreaProtocol, for: Square do
  def calculate(%Square{side: side}) do
    side * side
  end
end

# Boom and we get our answer.

# And we can add shapes, and operations on them at will.





