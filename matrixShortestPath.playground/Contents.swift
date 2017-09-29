//: Playground - noun: a place where people can play

import UIKit

//
//  Array2D.swift
//  testProject
//
//  Created by Mac on 9/28/17.
//  Copyright © 2017 Mac. All rights reserved.
//

import Foundation


//class declarations
class Array2D<T> {
    private var cols:Int
    private var rows:Int
    var matrix:[T]
    
    init(cols: Int, rows: Int, defaultValue:T) {
        self.cols = cols
        self.rows = rows
        self.matrix = Array(repeating:defaultValue, count:cols*rows)
    }
    
    subscript(row:Int, col:Int) -> T {
        get{
            return matrix[cols*row + col]
        }
        set {
            matrix[cols*row + col] = newValue
        }
    }
    
    func columnCount()-> Int{
        return cols
    }
    
    func rowCount() -> Int {
        return rows
    }
    
}

extension Array2D:CustomStringConvertible{
    var description:String {
        return String(matrix.enumerated().flatMap{ ($0.offset+1) % cols == 0 ? "\($0.element) \n" : "\($0.element) "})
    }
}

//Setup Functions
func buildRandomArray(size:Int) -> [Int]{
    var arr = Array(0...size)
    var randomArray:[Int] = []
    for _ in 0...size-1 {
        let count = UInt32(arr.count - 1)
        let randomIndex = Int(arc4random_uniform(count))
        let num = arr.remove(at: randomIndex)
        randomArray.append(num)
    }
    return randomArray
}

func transposeMatrixIntoArray(matrix: [[Int]]) -> Array2D<Int>{
    var result = Array2D<Int>(cols: matrix.count, rows: matrix.count, defaultValue: 0)
    for i in 0..<matrix.count {
        for j in 0..<matrix[0].count {
            result[i,j] = matrix[j][i]
        }
    }
    return result
}

func buildMatrix(size:Int) -> Array2D<Int>{
    var matrix:[[Int]] = []
    for _ in 1...size {
        matrix.append(buildRandomArray(size:size));
    }
    return transposeMatrixIntoArray(matrix: matrix)
}

//Find shortest from a specified row from the left side of the array to the right side of the array

func shortestPathFromIndex(for matrix:inout Array2D<Int>, index:Int) -> ([(Int,Int)], Int){ // Assuming a square matrix of max size 10x10
    let len = matrix.rowCount()
    var visitedHash:[Int:Int] = [:] // Store path cost at each node
    var visitQueue:[(Int, Int)] = [(index, 0)] //initialize queue for BFS
    var totalVisited:[(Int,Int)] = []
    let cols = matrix.columnCount()
    var parents: [Int:(Int,Int)] = [:]
    
    //Assigns lowest possible cost to get to each node
    while !visitQueue.isEmpty {
        let (col,row) = visitQueue.removeFirst()
        totalVisited.append((row,col))
        let hashnum = cols*row + col;
        let currVal = visitedHash[hashnum] ?? matrix[col,row]
        
        let top = col-1, mid = col, bot = col+1
        let nextRow = row+1
        if nextRow < len {
            if top >= 0 {
                let val = currVal + matrix[top,nextRow] //Value of current node
                let hashNum1 = cols*nextRow + top
                if visitedHash[hashNum1] == nil { // If node hasn't been visited yet, add it to the BFS queue
                    visitQueue.append((top,nextRow))
                }
                
                let cost = visitedHash[hashNum1] ?? Int(INT_MAX); // Assign lowest cost to the node
                if val < cost {
                    visitedHash[hashNum1] = min(val, cost)
                    parents[hashNum1] = (col,row) //Assign parent of lowest cost to currentNode
                }
            }
            
            let val = currVal + matrix[mid,nextRow]
            let hashNum2 = cols*nextRow + mid
            if visitedHash[hashNum2] == nil {
                visitQueue.append((mid,nextRow))
            }
            let cost = visitedHash[hashNum2] ?? Int(INT_MAX);
            if val < cost {
                visitedHash[hashNum2] = min(val, cost)
                parents[hashNum2] = (col,row)
            }
            
            if bot < len {
                let hashNum3 = cols*nextRow + bot
                if visitedHash[hashNum3] == nil {
                    visitQueue.append((bot,row+1))
                }
                let val = currVal + matrix[bot,nextRow]
                let cost = visitedHash[hashNum3] ?? Int(INT_MAX);
                if val < cost {
                    visitedHash[hashNum3] = min(val, cost)
                    parents[hashNum3] = (col,row)
                }
            }
        }
    }
    
    //Get the shortest path
    let filteredHash = visitedHash.filter{$0.key >= len * (cols-1)}
    let minValuePair = filteredHash.sorted{$0.value < $1.value}.first
    
    let minKey = minValuePair?.key ?? 404404404
    let minCost = minValuePair?.value ?? 404404404
    let endRow = minKey / cols
    let endCol = minKey % cols
    
    var path:[(Int,Int)] = [(endRow,endCol)]
    var nodeHash = minKey
    while parents[nodeHash] != nil {
        let (col,row) = parents[nodeHash]!
        path.insert((row,col), at: 0)
        nodeHash = cols*row + col;
    }
    
//    print("Optimal path from (0,\(index)) is: ", path)
//    print("Cost of this path is: \(minCost)")
    return (path, minCost)
}

var paths:[([(Int,Int)], Int)] = []
//Multithreading setup
class shortestPathOperation:Operation {
    private var done = false
    private var index:Int
    private var matrix:Array2D<Int>
    
    init(withIndex: Int, matrix:inout Array2D<Int>){
        self.index = withIndex
        self.matrix = matrix
    }
    
    override func main(){
        paths.append(shortestPathFromIndex(for: &matrix, index: index))
        isFinished = true
    }
    
    override var isFinished: Bool {
        get {
            return done
        }
        set {
            self.done = newValue
        }
    }
}

func multiThreadShortestPath(){
    
    var matrix = buildMatrix(size: 10);
    shortestPathFromIndex(for: &matrix, index: 2)
//    print(matrix)
    
    var ops:[Operation] = []
    for i in 0..<matrix.rowCount() {
        let op = shortestPathOperation(withIndex: i, matrix: &matrix)
        ops.append(op)
        //        guard i > 0 else {continue}
        //        op.addDependency(ops[i-1])
    }
    let queue = OperationQueue()
    queue.addOperations(ops, waitUntilFinished: true)
    
    let optimalPair = paths.sorted{$0.1 < $1.1}.first
    if let path = optimalPair?.0, let cost = optimalPair?.1 {
        print("For the following matrix:\n")
        print(matrix)
        print("The most Optimal path is: ", path)
        print("Cost of this path is: \(cost)")
    }
    
}

//var matrix = buildMatrix(size: 5);
//shortestPathFromIndex(for: &matrix, index: 2)
multiThreadShortestPath()

