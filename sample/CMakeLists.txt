SET(TARGET_NAME sample)
FILE(GLOB SRC
    main.cpp
    ) 

ADD_EXECUTABLE(${TARGET_NAME} ${SRC})

TARGET_INCLUDE_DIRECTORIES(${TARGET_NAME} PRIVATE
    "C:/Program Files/LLVM/include"
    )
TARGET_LINK_LIBRARIES(${TARGET_NAME} PRIVATE
    "C:/Program Files/LLVM/lib/libclang.lib"
    )
set_property(TARGET ${TARGET_NAME} PROPERTY CXX_STANDARD 20)
