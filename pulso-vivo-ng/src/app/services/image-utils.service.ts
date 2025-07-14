import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface ImageLoadResult {
  src: string;
  loaded: boolean;
  error: boolean;
  fallbackUsed: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ImageUtilsService {
  private imageCache = new Map<string, ImageLoadResult>();
  private defaultFallback = 'assets/images/producto-placeholder.jpg';

  constructor() {}

  /**
   * Loads an image with fallback support
   * @param src Primary image source
   * @param fallback Fallback image source (optional)
   * @returns Observable with image load result
   */
  loadImageWithFallback(src: string, fallback?: string): Observable<ImageLoadResult> {
    const cacheKey = `${src}_${fallback || this.defaultFallback}`;
    
    // Check cache first
    if (this.imageCache.has(cacheKey)) {
      return new BehaviorSubject(this.imageCache.get(cacheKey)!);
    }

    const subject = new BehaviorSubject<ImageLoadResult>({
      src: src,
      loaded: false,
      error: false,
      fallbackUsed: false
    });

    this.tryLoadImage(src, fallback || this.defaultFallback, subject, cacheKey);

    return subject.asObservable();
  }

  /**
   * Preloads an array of images
   * @param imageSources Array of image sources to preload
   * @returns Promise that resolves when all images are processed
   */
  preloadImages(imageSources: string[]): Promise<ImageLoadResult[]> {
    const promises = imageSources.map(src => this.preloadSingleImage(src));
    return Promise.all(promises);
  }

  /**
   * Gets the best available image source for a given primary source
   * @param src Primary image source
   * @param fallback Fallback image source
   * @returns The best available image source
   */
  getBestImageSource(src: string, fallback?: string): string {
    const cacheKey = `${src}_${fallback || this.defaultFallback}`;
    const cached = this.imageCache.get(cacheKey);
    
    if (cached) {
      return cached.fallbackUsed ? (fallback || this.defaultFallback) : src;
    }
    
    return src; // Return original if not cached
  }

  /**
   * Clears the image cache
   */
  clearCache(): void {
    this.imageCache.clear();
  }

  /**
   * Removes a specific image from cache
   * @param src Image source to remove from cache
   */
  removeFromCache(src: string): void {
    const keysToRemove = Array.from(this.imageCache.keys()).filter(key => key.startsWith(src));
    keysToRemove.forEach(key => this.imageCache.delete(key));
  }

  /**
   * Gets cache statistics
   * @returns Object with cache statistics
   */
  getCacheStats(): { totalCached: number; successfulLoads: number; failedLoads: number } {
    const entries = Array.from(this.imageCache.values());
    return {
      totalCached: entries.length,
      successfulLoads: entries.filter(entry => entry.loaded && !entry.error).length,
      failedLoads: entries.filter(entry => entry.error).length
    };
  }

  /**
   * Creates an image error handler function
   * @param fallbackSrc Fallback image source
   * @returns Error handler function
   */
  createImageErrorHandler(fallbackSrc?: string): (event: Event) => void {
    return (event: Event) => {
      const target = event.target as HTMLImageElement;
      if (target && target.src !== (fallbackSrc || this.defaultFallback)) {
        target.src = fallbackSrc || this.defaultFallback;
        target.classList.add('fallback-image');
      }
    };
  }

  /**
   * Creates a lazy loading observer for images
   * @param callback Function to call when image enters viewport
   * @param options Intersection observer options
   * @returns IntersectionObserver instance
   */
  createLazyLoadObserver(callback: (entries: IntersectionObserverEntry[]) => void, options?: IntersectionObserverInit): IntersectionObserver {
    const defaultOptions: IntersectionObserverInit = {
      root: null,
      rootMargin: '50px',
      threshold: 0.1
    };

    return new IntersectionObserver(callback, { ...defaultOptions, ...options });
  }

  /**
   * Attempts to load an image with fallback
   */
  private tryLoadImage(src: string, fallback: string, subject: BehaviorSubject<ImageLoadResult>, cacheKey: string): void {
    const img = new Image();
    
    img.onload = () => {
      const result: ImageLoadResult = {
        src: src,
        loaded: true,
        error: false,
        fallbackUsed: false
      };
      
      this.imageCache.set(cacheKey, result);
      subject.next(result);
      subject.complete();
    };

    img.onerror = () => {
      // Try fallback
      const fallbackImg = new Image();
      
      fallbackImg.onload = () => {
        const result: ImageLoadResult = {
          src: fallback,
          loaded: true,
          error: false,
          fallbackUsed: true
        };
        
        this.imageCache.set(cacheKey, result);
        subject.next(result);
        subject.complete();
      };

      fallbackImg.onerror = () => {
        const result: ImageLoadResult = {
          src: fallback,
          loaded: false,
          error: true,
          fallbackUsed: true
        };
        
        this.imageCache.set(cacheKey, result);
        subject.next(result);
        subject.complete();
      };

      fallbackImg.src = fallback;
    };

    img.src = src;
  }

  /**
   * Preloads a single image
   */
  private preloadSingleImage(src: string): Promise<ImageLoadResult> {
    return new Promise((resolve) => {
      const img = new Image();
      
      img.onload = () => {
        const result: ImageLoadResult = {
          src: src,
          loaded: true,
          error: false,
          fallbackUsed: false
        };
        resolve(result);
      };

      img.onerror = () => {
        const result: ImageLoadResult = {
          src: src,
          loaded: false,
          error: true,
          fallbackUsed: false
        };
        resolve(result);
      };

      img.src = src;
    });
  }
}