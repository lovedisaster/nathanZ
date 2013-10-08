using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Configuration;

namespace FolderFilterApp
{
    /// <summary>
    /// FilterPool is a stack of FolderFilter objects, the size of FilterPool is defined in app.config 'PoolSize'. 
    /// </summary>
    public static class FilterPool
    {
        /// <summary>
        /// The stack of FolderFilter. 
        /// </summary>
        private static Stack<FolderFilter> filterPool = new Stack<FolderFilter>();

        /// <summary>
        /// Max number of FolderFilter allowed in filterPool stack, the program will keep on creating new instance if the max number is not
        /// reached, and the program receives recycled FolderFilter instance after everytime it is used. 
        /// </summary>
        private static string poolSize = System.Configuration.ConfigurationManager.AppSettings["PoolSize"];

        /// <summary>
        /// Returns a FolderFilter object either from existing pool members or new instance.  
        /// </summary>
        /// <returns>FolderFilter object which has path filter functions.</returns>
        public static FolderFilter GetFilter(){
            if(filterPool.Count() < int.Parse(poolSize)){
                FolderFilter filter = new FolderFilter();
                filterPool.Push(filter);
            }
            FolderFilter returningFilter = filterPool.Pop();
            return returningFilter;
        }

        /// <summary>
        /// This method accepts returned FolderFilter instance and add it to the existing pool.  
        /// </summary>
        /// <param name="folderString">FolderFilter object which is returned from the calling class.</param>
        public static void ReturnFilter(FolderFilter returnedFilter){
            filterPool.Push(returnedFilter);
        }
    }
}
