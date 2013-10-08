using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace FolderFilterApp
{
    /// <summary>
    /// The program entrance class with executes Console commanders by intake user input and output result.
    /// </summary>
    class MainClass
    {
        static void Main(string[] args)
        {
            FolderFilter filter = FilterPool.GetFilter();
            Console.WriteLine("Please type the folder string with correct format: eg: 'a a/b a/b/c d d/e'.");
            string input = Console.ReadLine();
            string output = filter.FilterFolders(input);
            Console.WriteLine("The ones with sub directories are:");
            Console.WriteLine(output);
            FilterPool.ReturnFilter(filter);
        }
    }
}
